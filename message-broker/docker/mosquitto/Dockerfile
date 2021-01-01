FROM eclipse-mosquitto:latest

COPY mosquitto.conf /mosquitto/config/mosquitto.conf
COPY passwd /mosquitto/config/passwd

CMD /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf -p $PORT
