#include <ESP8266WiFi.h>
#include <DNSServer.h>
#include <WiFiClient.h>
#include <EEPROM.h>
#include <ESP8266WebServer.h>
#include <ESP8266HTTPClient.h>
#include <AsyncHTTPRequest_Generic.h>
#include <Ticker.h>
#include <ESP8266TrueRandom.h>
#include "define.h"

// 10s = 10 seconds to not flooding the server
#define HTTP_REQUEST_INTERVAL_MS 10000
#define PINOUT 0
#define DIVISOR '/'

const String AUTH_KEY = "Authorization";
const String CLIENT_KEY = "Client-Id";
const String HOST = "http://flask-message-broker.herokuapp.com/api";
const String SUBSCRIBE = "subscribe";
const String TOPIC = "home-light";
const String TOPIC_RESPONSE = "home-light-response";
const String PUBLISH = "publish";
const String MESSAGE = "message";
const String ON = "ON";
const String OFF = "OFF";

String actuatorStatus;
String clientId = "";
String topicResponse = "";

const IPAddress apIP(192, 168, 1, 1);
const char* apSSID = "ESP8266_SETUP";
boolean settingMode;
String ssidList;

DNSServer dnsServer;
ESP8266WebServer webServer(80);

HTTPClient request;
AsyncHTTPRequest asyncRequest;

void sendRequest(void);
Ticker sendAsyncRequest(sendRequest, HTTP_REQUEST_INTERVAL_MS, 0, MILLIS);


void setup() {
  Serial.begin(115200);
  EEPROM.begin(512);
  delay(10);

  pinMode(PINOUT, OUTPUT);
  digitalWrite(PINOUT, HIGH);
  actuatorStatus = OFF;
  
  if (restoreConfig()) {
    if (checkConnection()) {
      settingMode = false;
      evaluateClientId();
      startWebServer();
      
      asyncRequest.setDebug(false);
      asyncRequest.onReadyStateChange(handleResponse);
      asyncRequest.setTimeout(3600);
      sendAsyncRequest.start();
      sendRequest();
      
      return;
    }
  }
  settingMode = true;
  setupMode();
}

void loop() {
  if (settingMode) {
    dnsServer.processNextRequest();
  } else {
    sendAsyncRequest.update();
    
    if(topicResponse == ON){
      digitalWrite(PINOUT, LOW);
    } else if(topicResponse == OFF){
      digitalWrite(PINOUT, HIGH);
    }

    sendTopicResponse();
  }
  webServer.handleClient();
}



void sendRequest(void){
  static bool requestOpenResult;
  
  if (asyncRequest.readyState() == readyStateUnsent || asyncRequest.readyState() == readyStateDone){
    String tmp = HOST + DIVISOR + SUBSCRIBE + DIVISOR + TOPIC;
    const char* url = tmp.c_str();
    Serial.print(clientId);
    Serial.print(": ");
    Serial.println(url);
    requestOpenResult = asyncRequest.open("GET", url);
    asyncRequest.setReqHeader(AUTH_KEY.c_str(), AUTH_VAL.c_str());
    asyncRequest.setReqHeader(CLIENT_KEY.c_str(), clientId.c_str());
    //Serial.println(request.headers());
    
    if (requestOpenResult){
      asyncRequest.send();
    } else {
      Serial.println("Can't send bad request");
    }
  } else {
    Serial.println("Resquest in progress...");
  }
}

void handleResponse(void* optParm, AsyncHTTPRequest* request, int readyState){
  if (readyState == readyStateDone){
    int16_t statusCode = request->responseHTTPcode();
    
    if(statusCode == HTTP_CODE_OK){

      String response = request->responseText();
      Serial.print("Async http response text: ");
      Serial.println(response);

      bool found = false;
      if(response == ON){
        found = actuatorStatus != ON;
        actuatorStatus = ON;
      } else if(response == OFF){
        found = actuatorStatus != OFF;
        actuatorStatus = OFF;
      }

      if(found){
        topicResponse = response;
      }
      
    } else {
      Serial.print("Async http response code: ");
      Serial.println(statusCode);
    }
     
    request->setDebug(false);
  }
}



void sendTopicResponse(){
  if(topicResponse != ""){
    String url = HOST + DIVISOR + PUBLISH + DIVISOR + TOPIC_RESPONSE + DIVISOR + MESSAGE + DIVISOR + topicResponse + "?expire=never";
    topicResponse = "";
    Serial.print(clientId);
    Serial.print(": ");
    Serial.println(url);
    request.begin(url);
    request.addHeader(AUTH_KEY, AUTH_VAL);
    request.addHeader(CLIENT_KEY, clientId);
    int httpCode = request.GET();
    Serial.print("Topic response status: ");
    Serial.println(httpCode);
    request.end();
  }
}


void evaluateClientId(){
  char first = char(EEPROM.read(96));
  if(first == 'a'){
    Serial.println("Load client id from eeprom.");
    for (int i = 96; i < 111; ++i) {
      clientId += char(EEPROM.read(i));
    }
  } else {
    Serial.println("Create client id and save to eeprom.");
    int uniqueInt = ESP8266TrueRandom.random(1000, 9999);
    clientId = "actuator-" + String(uniqueInt);

    for (int i = 96; i < 111; ++i) {
      EEPROM.write(i, 0);
    }
    for (int i = 0; i < clientId.length(); ++i) {
      EEPROM.write(96 + i, clientId[i]);
    }
    EEPROM.commit();
  }

  Serial.print("Client id: ");
  Serial.println(clientId);
}


boolean restoreConfig() {
  Serial.println("Reading EEPROM...");
  String ssid = "";
  String pass = "";
  if (EEPROM.read(0) != 0) {
    for (int i = 0; i < 32; ++i) {
      ssid += char(EEPROM.read(i));
    }
    Serial.print("SSID: ");
    Serial.println(ssid);
    for (int i = 32; i < 96; ++i) {
      pass += char(EEPROM.read(i));
    }
    Serial.print("Password: ");
    Serial.println(pass);
    WiFi.begin(ssid.c_str(), pass.c_str());
    return true;
  }
  else {
    Serial.println("Config not found.");
    return false;
  }
}

boolean checkConnection() {
  int count = 0;
  Serial.print("Waiting for Wi-Fi connection");
  while ( count < 30 ) {
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println();
      Serial.println("Connected!");
      return (true);
    }
    delay(500);
    Serial.print(".");
    count++;
  }
  Serial.println("Timed out.");
  return false;
}

void startWebServer() {
  if (settingMode) {
    Serial.print("Starting Web Server at ");
    Serial.println(WiFi.softAPIP());
    webServer.on("/settings", []() {
      String s = "<h1>Wi-Fi Settings</h1><p>Please enter your password by selecting the SSID.</p>";
      s += "<form method=\"get\" action=\"setap\"><label>SSID: </label><select name=\"ssid\">";
      s += ssidList;
      s += "</select><br>Password: <input name=\"pass\" length=64 type=\"password\"><input type=\"submit\"></form>";
      webServer.send(200, "text/html", makePage("Wi-Fi Settings", s));
    });
    webServer.on("/setap", []() {
      for (int i = 0; i < 96; ++i) {
        EEPROM.write(i, 0);
      }
      String ssid = urlDecode(webServer.arg("ssid"));
      Serial.print("SSID: ");
      Serial.println(ssid);
      String pass = urlDecode(webServer.arg("pass"));
      Serial.print("Password: ");
      Serial.println(pass);
      Serial.println("Writing SSID to EEPROM...");
      for (int i = 0; i < ssid.length(); ++i) {
        EEPROM.write(i, ssid[i]);
      }
      Serial.println("Writing Password to EEPROM...");
      for (int i = 0; i < pass.length(); ++i) {
        EEPROM.write(32 + i, pass[i]);
      }
      EEPROM.commit();
      Serial.println("Write EEPROM done!");
      String s = "<h1>Setup complete.</h1><p>device will be connected to \"";
      s += ssid;
      s += "\" after the restart.";
      webServer.send(200, "text/html", makePage("Wi-Fi Settings", s));
      ESP.restart();
    });
    webServer.onNotFound([]() {
      String s = "<h1>AP mode</h1><p><a href=\"/settings\">Wi-Fi Settings</a></p>";
      webServer.send(200, "text/html", makePage("AP mode", s));
    });
  } else {
    Serial.print("Starting Web Server at ");
    Serial.println(WiFi.localIP());
    webServer.on("/", []() {
      String s = "<h1>STA mode</h1><p><a href=\"/reset\">Reset Wi-Fi Settings</a></p>";
      webServer.send(200, "text/html", makePage("STA mode", s));
    });
    webServer.on("/reset", []() {
      for (int i = 0; i < 96; ++i) {
        EEPROM.write(i, 0);
      }
      EEPROM.commit();
      String s = "<h1>Wi-Fi settings was reset.</h1><p>Please reset device.</p>";
      webServer.send(200, "text/html", makePage("Reset Wi-Fi Settings", s));
    });
  }
  webServer.begin();
}

void setupMode() {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  int n = WiFi.scanNetworks();
  delay(100);
  Serial.println("");
  for (int i = 0; i < n; ++i) {
    ssidList += "<option value=\"";
    ssidList += WiFi.SSID(i);
    ssidList += "\">";
    ssidList += WiFi.SSID(i);
    ssidList += "</option>";
  }
  delay(100);
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255, 255, 255, 0));
  WiFi.softAP(apSSID);
  dnsServer.start(53, "*", apIP);
  startWebServer();
  Serial.print("Starting Access Point at \"");
  Serial.print(apSSID);
  Serial.println("\"");
}

String makePage(String title, String contents) {
  String s = "<!DOCTYPE html><html><head>";
  s += "<meta name=\"viewport\" content=\"width=device-width,user-scalable=0\">";
  s += "<title>";
  s += title;
  s += "</title></head><body>";
  s += contents;
  s += "</body></html>";
  return s;
}

String urlDecode(String input) {
  String s = input;
  s.replace("%20", " ");
  s.replace("+", " ");
  s.replace("%21", "!");
  s.replace("%22", "\"");
  s.replace("%23", "#");
  s.replace("%24", "$");
  s.replace("%25", "%");
  s.replace("%26", "&");
  s.replace("%27", "\'");
  s.replace("%28", "(");
  s.replace("%29", ")");
  s.replace("%30", "*");
  s.replace("%31", "+");
  s.replace("%2C", ",");
  s.replace("%2E", ".");
  s.replace("%2F", "/");
  s.replace("%2C", ",");
  s.replace("%3A", ":");
  s.replace("%3A", ";");
  s.replace("%3C", "<");
  s.replace("%3D", "=");
  s.replace("%3E", ">");
  s.replace("%3F", "?");
  s.replace("%40", "@");
  s.replace("%5B", "[");
  s.replace("%5C", "\\");
  s.replace("%5D", "]");
  s.replace("%5E", "^");
  s.replace("%5F", "-");
  s.replace("%60", "`");
  return s;
}
