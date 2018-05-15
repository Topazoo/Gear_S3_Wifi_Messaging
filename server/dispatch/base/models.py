#!/usr/bin/python
"""
Author: Peter Swanson
            pswanson@ucdavis.edu

Description: Classes to represent text message information and the users that send and receive them

Version: Python 2.7, Django 1.9.13
"""

from __future__ import unicode_literals
from django.db import models
from django.core.validators import RegexValidator
import smtplib

class User(models.Model):
    ''' Class to represent the watch user '''

    gmail_username = models.CharField(max_length=20, blank=False)

    gmail_password = models.CharField(max_length=20, blank=False)

    gmail_server = models.CharField(max_length=20, blank=False)


class Message(models.Model):
    ''' Class to represent text messages '''

    user = models.OneToOneField(User, on_delete=models.CASCADE)

    to_address = models.CharField(max_length=20, blank=False, default='4152094084@vtext.com')
                                    #validators=[ RegexValidator(regex=r'^\D?(\d{3})\D?\D?(\d{3})\D?(\d{4})$',
                                     #                           message="Invalid phone number!"), ])

    from_address = models.CharField(max_length=20, blank=False, default='4152094084')
                                       #validators=[RegexValidator(regex=r'^\D?(\d{3})\D?\D?(\d{3})\D?(\d{4})$',
                                        #                          message="Invalid phone number!"), ])

    text = models.TextField(blank=False)


    def send_message(self):
        '''Sends a message to a email'''

        server = smtplib.SMTP(str(self.user.gmail_server))
        server.ehlo()
        server.starttls()
        server.login(str(self.user.gmail_username), str(self.user.gmail_password))
        server.sendmail(str(self.from_address), str(self.to_address), str(self.text))
        server.quit()