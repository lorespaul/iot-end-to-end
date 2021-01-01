import paho.mqtt.client as mqtt
import time

#hostname = "127.0.0.1"
hostname = "mymosquitto.herokuapp.com"
client_name = "moquitto_publisher"

client = mqtt.Client(client_name)
client.username_pw_set("root", "Gibson2009-")

def on_connect(client, userdata, flags, rc):
    global loop_flag
    loop_flag = False
    if rc == 0:
        print("Connected to MQTT Broker!")
    else:
        print("Failed to connect, return code %d\n", rc)

client.on_connect = on_connect

client.connect(hostname, port=80)
client.loop_start()

loop_flag = True
counter = 0
while loop_flag:
    print("waiting for callback to occur ", counter)
    time.sleep(1)
    counter += 1

topic = "house/light/outdoor"
client.publish(topic, "ciaone")

client.loop_stop()
#docker run -it -d --name my_mosquitto -p 80:1883 -p 9001:9001 -v c:/hostmount/mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf -v c:/hostmount/mosquitto/config:/mosquitto/config -v c:/hostmount/mosquitto/data:/mosquitto/data -v c:/hostmount/mosquitto/log:/mosquitto/log eclipse-mosquitto