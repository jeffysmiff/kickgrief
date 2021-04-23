import os

from time import sleep
from flask import Flask
from flask import render_template, request, redirect

# create and configure the app
app = Flask(__name__, instance_relative_config=True)

# a simple page that says hello
@app.route('/',methods=['GET','POST'])
def kick():
    if request.method == "POST":
        os.system('sudo sysctl -w net.ipv4.ip_forward=0')
        sleep(10)
        os.system('sudo sysctl -w net.ipv4.ip_forward=1')
        return render_template('kick.html',title='kick') 
    return render_template('kick.html',title='kick')

if __name__ == "__main__":
    app.run()
