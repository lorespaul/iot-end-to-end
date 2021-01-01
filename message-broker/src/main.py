import flask
import flask_httpauth
import tinydb
import threading
import hashlib
import time
import uuid
import os
import datetime

USER = 'root'
PASSWD = 'cf7010e54edd6f7ee2a7f09a600cda65308f4c917c3012408138ec497ee79219'
CLIENT_ID_KEY = 'Client-Id'
DB_FILE = 'db.json'

app = flask.Flask(__name__)
port = int(os.environ.get('PORT', 5000))
auth = flask_httpauth.HTTPBasicAuth()
lock = threading.Lock()
db = tinydb.TinyDB(DB_FILE)


@auth.verify_password
def verify_password(username, password):
    if username == USER and hashlib.sha256(password.encode()).hexdigest() == PASSWD:
        return username


@app.route('/api/health')
def health():
    return flask.Response(status=200)


@app.route('/api/db')
@auth.login_required
def get_db():
    try:
        with open(DB_FILE, 'r') as file:
            data = file.read()
            return data
    except:
        pass
    return flask.Response(status=404)



@app.route('/api/publish/<topic>/message/<message>')
@auth.login_required
def publish(topic, message):
    client_id = flask.request.headers.get(CLIENT_ID_KEY)
    if client_id is None or client_id == '':
        return flask.Response(response='Client-Id header not found or not properly evaluated', status=500)

    expire = flask.request.args.get('expire')
    if expire is None or expire == '':
        expire = '600'

    query = tinydb.Query()

    lock.acquire()

    try:
        docs = db.search(query.topic == topic)
        if expire == 'never' and len(docs) > 0:
            db.update({ 'message': message, 'created_by': client_id }, query.id == docs[0]['id'])
        else:
            guid = str(uuid.uuid1())
            max_queue = -1
            if len(docs) > 0:
                max_queue = max(doc['queue'] for doc in docs)
            db.insert({ 
                'id': guid,
                'topic': topic,
                'message': message,
                'queue': max_queue + 1,
                'expire': expire,
                'created_by': client_id,
                'created_at': datetime.datetime.now().strftime("%d/%m/%Y %H:%M:%S"),
                'readed_from': []
            })
    finally:
        lock.release()

    return flask.Response(status=201)


@app.route('/api/subscribe/<topic>')
@auth.login_required
def subscribe(topic):
    client_id = flask.request.headers.get(CLIENT_ID_KEY)
    if client_id is None or client_id == '':
        return flask.Response(response='Client-Id header not found or not properly evaluated', status=500)

    poll = flask.request.args.get('poll')
    last = flask.request.args.get('last')
    if last is None or last == '':
        last = 'false'
    
    counter = 1 if poll == 'true' else 25
    message = None
    while counter > 0:

        lock.acquire()

        try:
            query = tinydb.Query()
            docs = db.search((query.topic == topic) & ~(query.created_by == client_id) & ~(query.readed_from.any(client_id)))
            if len(docs) > 0:
                docs.sort(key=lambda x: x['queue'])
                
                for doc in docs:
                    created_at = datetime.datetime.strptime(doc['created_at'], "%d/%m/%Y %H:%M:%S")
                    expire = doc['expire']

                    if expire.isnumeric() and (created_at + datetime.timedelta(seconds=int(expire)) < datetime.datetime.now()):
                        query = tinydb.Query()
                        db.remove(query.id == doc['id'])
                    elif last == 'false' or (last == 'true' and doc['id'] == docs[len(docs) - 1]['id']):
                        if doc['expire'] != 'never':
                            readed_from = doc['readed_from']
                            readed_from.append(client_id)
                            db.update({ 'readed_from': readed_from }, query.id == doc['id'])
                        message = doc['message']
                        break
                
                if message is not None:
                    break
        finally:
            lock.release()

        time.sleep(1)
        counter -= 1

    if message is None:
        return flask.Response(status=404)
    
    return message


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=port, threaded=True)