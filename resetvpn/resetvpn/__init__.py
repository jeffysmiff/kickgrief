import os

from time import sleep
from flask import Flask
from flask import render_template, request, redirect

# create and configure the app
app = Flask(__name__, instance_relative_config=True)

# a simple page that says hello
@app.route('/',methods=['GET','POST'])
def reset_vpn():
    if request.method == "POST":
        os.system('sudo service openvpn stop')
        sleep(5)
        os.system('sudo service openvpn start')
        sleep(10)
        return render_template('resetvpn.html',title='Reset VPN') 
    return render_template('resetvpn.html',title='Reset VPN')

if __name__ == "__main__":
    app.run()
