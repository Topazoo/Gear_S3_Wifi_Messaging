#!/usr/bin/python
"""
Author: Peter Swanson
            pswanson@ucdavis.edu

Description: Views to handle HTTP requests

Version: Python 2.7, Django 1.9.13
"""
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from models import User, Message
import os, sys

def read_ini():
    ''' Reads the configuration file '''

    ini_dict = {}

    # Parse config.ini and record values
    if os.path.isfile('config.ini'):
        with open('config.ini') as config:
            for line in config:
                index = line.find("=")

                if index == -1:
                    print "config.ini error - Invalid Syntax"
                    sys.exit(1)

                ini_dict[line[:index]] = line[index+1:].strip()

            config.close()

        # Check errors
        if "username" not in ini_dict.keys():
            print "config.ini error - No Username Specified"
            sys.exit(1)
        if "password" not in ini_dict.keys():
            print "config.ini error - No Password Specified"
            sys.exit(1)
        if "server" not in ini_dict.keys():
            ini_dict["server"] = "smtp.gmail.com:587"
    else:
        print "config.ini error - File Not Found"
        sys.exit(1)

    return ini_dict

@csrf_exempt
def base(request):
    ''' Send out post requests via SMTP '''

    # Read user info from config.ini
    ini = read_ini()
    user = User(gmail_username=ini['username'], gmail_password=ini['password'], gmail_server=ini['server'])

    # Send message from user
    if request.method == 'POST':
        message = Message(user=user,text=request.POST['q'])
        message.send_message()
    else:
        message = Message(user=user, text='NO POST')

    # Render message details (Change to HttpResponse)
    return render(request, 'base/home.html', {'message': message})