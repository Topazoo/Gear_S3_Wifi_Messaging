#!/usr/bin/python
"""
Author: Peter Swanson
            pswanson@ucdavis.edu

Description: Tests sending messages from the server via POST request

Version: Python 2.7, Django 1.9.13

Requires: requests
"""

import requests

text = str(raw_input("Enter text to send >>> "))
to_number = str(raw_input("Enter a number to send it to >>> "))
from_number = "4152094084"
carrier = "Verizon"

client = requests.session()
url = 'http://52.25.144.62/'

# Retrieve the CSRF token first
client.get(url)  # sets cookie
if 'csrftoken' in client.cookies:
    # Django 1.6 and up
    csrftoken = client.cookies['csrftoken']
else:
    # older versions
    csrftoken = client.cookies['csrf']

data = dict(message=text,to_number=to_number, from_number=from_number, carrier=carrier, csrfmiddlewaretoken=csrftoken)
r = client.post(url, data=data, headers=dict(Referer=url))