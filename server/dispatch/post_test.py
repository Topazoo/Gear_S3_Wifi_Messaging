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

client = requests.session()
url = 'http://127.0.0.1:8000'

# Retrieve the CSRF token first
client.get(url)  # sets cookie
if 'csrftoken' in client.cookies:
    # Django 1.6 and up
    csrftoken = client.cookies['csrftoken']
else:
    # older versions
    csrftoken = client.cookies['csrf']

data = dict(q=text, csrfmiddlewaretoken=csrftoken, next='/')
r = client.post(url, data=data, headers=dict(Referer=url))