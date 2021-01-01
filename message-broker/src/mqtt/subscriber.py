import paho.mqtt.client as mqtt
#import time

#hostname = "127.0.0.1"
hostname = "mymosquitto.herokuapp.com"
client_name = "moquitto_subscriber"

client = mqtt.Client(client_name)
client.username_pw_set("root", "Gibson2009-")
client.connect(hostname, port=80)

topic = "house/light/outdoor"

def on_message(client, userdata, message):
    print("message received", str(message.payload.decode("utf-8")), "on topic", message.topic)
    # print("message topic=", message.topic)
    # print("message qos=", message.qos)
    # print("message retain flag=", message.retain)

client.subscribe(topic)
client.on_message = on_message


client.publish(topic, "ON")

client.loop_forever()

#time.sleep(10)
#client.loop_stop()