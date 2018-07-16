#!/usr/bin/python
"""
Author: Peter Swanson
            pswanson@ucdavis.edu

Description: Views to handle HTTP requests

Version: Python 2.7, Django 1.9.13
"""

from django.shortcuts import render
from models import User, Message
import os, sys, requests

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
        if "key" not in ini_dict.keys():
            ini_dict["key"] = "NONE"
    else:
        print "config.ini error - File Not Found"
        sys.exit(1)

    return ini_dict

def add_ext(post, key):
    ''' Add the correct extension to text the number - Requires a Whitepages Pro developer account '''
    
    phone_number = post['to_number']

    if 'carrier' in post.keys():
        carrier = post['carrier']
    else:
        carrier = "verizon"

        if key != "NONE":
            # Query white pages for carrier data 
            url = "https://proapi.whitepages.com/3.0/phone_intel?phone=" + phone_number
            api_key = "&api_key=" + key
            url += api_key
            res = requests.get(url)
            carrier = str(res.json()["carrier"]).lower()

    if "verizon" in carrier:
        return str(phone_number) + "@vtext.com"
    elif "at&t" in carrier or "att" in carrier:
        return str(phone_number) + "@txt.att.net"
    elif "sprint" in carrier:
       return str(phone_number) + "@messaging.sprintpcs.com"
    elif "mobile" in carrier:
       return str(phone_number) + "@tmomail.net"
    else:
        return str(phone_number) + "@vtext.com"

def base(request):
    ''' Send out post requests via SMTP '''

    # Read user info from config.ini
    ini = read_ini()
    user = User(gmail_username=ini['username'], gmail_password=ini['password'], gmail_server=ini['server'], wp_API_key=ini['key'])

    # Send message from user
    if request.method == 'POST':
        to = add_ext(request.POST, ini["key"])
        from_n = request.POST['from_number']
        message = Message(user=user, to_address=to, from_address=from_n ,text=request.POST['message'])
        message.send_message()
    else:
        message = Message(user=user, text='NO POST')

    # Render
    return render(request, 'base/home.html', {'message': message})