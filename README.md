# IoT end to end

This repository contains three folders:

* iot_esp is an Arduino project that can be deployed to an esp8266 to perform on/off switch
* message-broker is a simple bus made in python with flask, conteinerized with docker and ready to deploy on heroku
* on_off_app is a flutter app that can be used to switch on and off GPIO0 of esp8266

Useful hardware on Amazon.it:

* [esp8266 with relay switch](https://www.amazon.it/gp/product/B07RKVJ3S8/ref=ppx_yo_dt_b_asin_title_o00_s00?ie=UTF8&psc=1)
* [esp8266 programmer](https://www.amazon.it/AZDelivery-ESP8266-Arduino-adattatore-gratuito/dp/B078J7LDLY/ref=sr_1_14?__mk_it_IT=%C3%85M%C3%85%C5%BD%C3%95%C3%91&dchild=1&keywords=esp8266+programmer&qid=1609518234&s=electronics&sr=1-14)
* [5V/600mA power supply](https://www.amazon.it/gp/product/B079138QY1/ref=ppx_yo_dt_b_asin_title_o00_s00?ie=UTF8&psc=1)


### Setup message broker

1. In message-broker/src/main.py change `PASSWD` variable with sha256 value of your password
2. Go to heroku and create a new app
3. In message-broker/docker/build.sh replace all occurence of string `flask-message-broker` with your app name
4. Download heroku cli and perform login
5. Download and install docker
6. Launch `heroku container:login` to login on heroku registry with docker

After that you will be able to deploy your app by launch this commands from message-broker/docker folder:

1. `./build.sh`
2. `docker push registry.heroku.com/<app_name>/web`
3. `heroku container:release web -a <app_name>`


### Setup esp8266

* Create a file named `define.h` in iot_esp with this content

> #ifndef DEFINE_H
> #define DEFINE_H
> const String AUTH_VAL = "Basic <base64_encoding>";
> #endif

<base64_encoding> is base64 encoding of credentials to access message broker: "root:<your_password>"

* Setup Arduino IDE with esp8266 board
* Connect esp8266 to pc with programmer or with Arduino. While doing this, short-circuit pin GND and GPIO0 of esp8266 in order to enable program loading.
* Deploy code


### Setup flutter app

* Create a file `.env` in on_off_app folder with this content:

`AUTH_VAL=Basic <base64_encoding>`

like the in `define.h` used for esp8266

* Build and launch app on ios/android/windows.


#### Other information

Message broker is used to exchange messages between flutter app and esp8266.

Esp8266 listen for messages on topic `home-light` and change his status based on messages content. Flutter app send these messages that are managed in a queue.

Esp8266 send a message on topic `home-light-reponse` at boot and on status change, but set `expire=never` on request so this message is not enqueued. Instead it will update a previouse message (that can't expire) with new sent string. So every topic can have only one message not expirable.

Flutter app listen on this topic in order to show current status of the actuator.


Topic names are hard coded in flutter app and iot_esp.ino
