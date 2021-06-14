#!/usr/bin/python3.7
import sys
import logging
logging.basicConfig(stream=sys.stderr)
sys.path.insert(0,"/var/www/resetvpn/")

from resetvpn import app as application
#application.secret_key = 'Add your secret key'
