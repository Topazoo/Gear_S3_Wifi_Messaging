#!/usr/bin/python
"""
Author: Peter Swanson
            pswanson@ucdavis.edu

Description: Configures urls to trigger views

Version: Python 2.7, Django 1.9.13
"""

from django.conf.urls import url
from . import views

urlpatterns = [
    url(r'^$', views.base, name='base'),
]
