FROM python:3.8

RUN pip install flask && \
    pip install flask_httpauth && \
    pip install tinydb

COPY ./main.py /app/main.py
WORKDIR /app

ENTRYPOINT [ "python" ]
CMD [ "main.py" ]