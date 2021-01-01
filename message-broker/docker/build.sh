#!/bin/bash

image="flask-message-broker"
tag="registry.heroku.com/flask-message-broker/web"


old_image="$(docker images -q ${image}:latest)"
if [ old_image != "" ]; then
    docker rmi -f "$old_image"
fi

cp ../src/main.py ./main.py
docker build -t "$image" .
docker tag flask-message-broker registry.heroku.com/flask-message-broker/web
rm ./main.py

#heroku container:login
#docker push registry.heroku.com/flask-message-broker/web
#heroku container:release web -a flask-message-broker