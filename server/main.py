import os, random
from flask import Flask, request, Response, send_from_directory
app = Flask(__name__, static_url_path='')

os.system('mkdir uploaded_data')

def UID():
    seed = random.getrandbits(32)
    while True:
       yield seed
       seed += 1

id_generator = UID()
def getUID():
    return str(next(id_generator))

# Handle incoming requests to "neural"-ize images
@app.route("/", methods=["POST"])
def art():
    if not len(request.form['image']) == 0:
        imageID = getUID()

        os.system('mkdir uploaded_data/'+imageID)
        with open("uploaded_data/"+ imageID +"/"+ imageID + ".jpeg", "wb") as fh:
            fh.write((request.form['image']).decode('base64'))

        image_url = request.url+"img/"+ imageID +".jpeg";

        os.system('''python evaluate.py
                    --checkpoint models/rain_princess.ckpt
                    --in-path uploaded_data/'''+ imageID + '''
                    --out-path uploaded_data/'''+ imageID)

        return image_url

    else:
        return Response({"Error": "Missing parameters."}, 'text/json')

@app.route('/img/<path:id>', methods=['GET'])
def get(id):
    raw = id.split('.')[0]
    return send_from_directory('uploaded_data/'+raw, id)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
