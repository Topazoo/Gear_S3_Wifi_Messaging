# Gear S3 Wifi Messaging
### Author: Peter Swanson
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Python 2.7](https://img.shields.io/badge/Python-2.7-brightgreen.svg)](https://www.python.org/downloads/release/python-2714/)
[![Django 1.9.13](https://img.shields.io/badge/Django-1.9.13-brightgreen.svg)](https://pypi.org/project/Django/1.9.13/)
[![requests 2.19.1](https://img.shields.io/badge/requests-2.19.1-brightgreen.svg)](https://pypi.org/project/requests/)

## Background
Until now, the Samsung Gear S3 Classic did not allow users to send messages over Wifi.

<b>This application allows messages to be sent from the watch over Wifi</b>

This repository contains the application client and server. The client runs natively on the watch and communicates with the server via the Tizen HTTP library. The server sends messages using the Gmail SMTP server.

## Server Deployment
### Starting the server:
This server can be run on your local machine using Django or deployed to the cloud. For the latter I prefer using:
- An AWS Ubuntu instance (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html)
- Nginx and gunicorn (https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-16-04)

### Create a config.ini file:
This file should be placed in the <b>server/dispatch</b> directory (the directory that contains 
<b>manage.py</b>).

This file must adhere to the following format:
```
username=USERNAME
password=PASSWORD
server=SERVER
key=KEY
```
Where the lefthand value is your SMTP server username, password, and server respectively. 

Notes: If you are using gmail, the server argument is optional. In this case the prior two arguments are your gmail
username and password respectively. The key argument is optional and only necessary when using Whitepages for phone number carrier lookup. 

## Functionality
### Running the server locally:
Begin by migrating the database.
```
$ python manage.py makemigrations
$ python manage.py migrate
```
Then run the server.
```
python manage.py runserver
```
You can visit the server at http://127.0.0.1:8000/, however it is meant to be a RESTful enpoint 
rather than a real website.

### Sending a message to/from the server:
For now, you can send a message via POST request with a valid CSRF token.
The <b>post_test.py</b> file records user input and sends it to the server as a POST request.
```
$ python post_test.py
```
Note: Requires the URL of a running server instance.

## Files
 - server/dispatch/ - Contains Django server files
    - manage.py - Facilitates interaction with server
    - post_test.py - Test sending a POST request to the server
    - base/urls.py - Views to run when a url is visited
    - base/views.py - Functions to run or render content per url
    - base/models.py - Data structures in Django format
    - base/templates/ - HTML templates to render with dynamic content
    - dispatch/settings.py - Django project settings
 - client/ - Contains C code for client and Tizen permissions for Samsung Wearables
    - src/watch_sample.c - C source code for client
    
## Requirements
- Server
   - Python 2.7 - https://www.python.org/downloads/release/python-2714/
   - Django 1.9.13 - https://pypi.org/project/Django/1.9.13/
   - Requests 2.19.1 - https://pypi.org/project/requests/
- Client
   - Tizen Studio - https://developer.tizen.org/ko/development/tizen-studio?langredirect=1
   - Tizen Wearable v4.0
