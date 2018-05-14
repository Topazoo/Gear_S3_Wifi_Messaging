#!/bin/bash   
#Author: Peter Swanson
#Creates a Django Application based on user entered parameters

#DEVELOPMENT CHECKLIST:
	#1 A script to set up a basic instance with a built-in database		<>
	#2 A seperate script to add Gunicorn and Nginx to the instance 		<>
	#3 Modify first script that detects errors and works on multiple OS' >
	#4 Make first script customizeable									<>
	#5 Store templates on an s3 bucket and grab what's needed
	#6 A script that installs Python, setuptools, and pip if possible
	#7 A few templates the user can select
	#8 Interchangeable applications (blog, shop, gallery, video, etc.)
	#9 Additional templates and features

#CRITICAL: New script to get it server ready
	# Needs to detect the OS

#ADD: Add command line options for more customization 
    # - Needs: A parser for various arguments
#ADD: Add support for multiple OS'
	# - Needs: Testing with virtualbox
#ADD: Add support for multiple versions of Python
	# Needs: - To be integrated with Pip install to get correct versions

#CHANGE: Make setting up static and templates its own function
	
#Potential ADD: Add support for multiple versions of Django
	# - Needs: Better understanding of the quirks of each Django versions

# Command line arguments:
DETONATE=1
CDETONATE=0
DETARGS=""
CUSTOM=0
S3CMD=1

# Parsed command line arguments:
CLA=()

# Detected:
VERSION=`python -c "import sys;version='{info[0]}.{info[1]}'.format(info=list(sys.version_info[:2]));sys.stdout.write(version)";`
VALID=0
PWDIR="UNKNOWN"

#Colors:
RED='\033[0;91m'
GREEN='\033[0;92m'
YL='\033[0;93m' 
BLUE='\033[0;34m'
LBLU='\033[0;96m'
NC='\033[0m'

create_tracer ()
{
	touch .trace
	
}

name_app ()
{
    read -r -p "Please enter a name for the application: " APPLNAME
    echo
} # Read name of application from user
# !! ADD: namecheck of some kind! No reserved words

create_venv ()
{
    echo 
    virtualenv -p /usr/bin/python$* venv
    echo -e "${GREEN}Successfully created Python $VERSION virtual environment${NC}" 
    echo
} # Create a python virtual environment

pick_version ()
{
    echo "Choose a Python version: "
	echo "1. Autodetect"
	echo "2. Python 2.7"
	echo "3. Python 3.4"
	echo "4. Python 3.5"
	echo "5. Custom"
	echo
	echo -n "Enter selection: "
	read PICKED
	
	if [[ "$PICKED" =~ ^[1-5]+$ ]]; then
		:	
	else
		echo -e "${RED}$PICKED is not an option!${NC}"
		echo
		pick_version	
	fi
	
	VERSION=$PICKED
		
} # This records the user's Python venv choice and validates recursively

custom_version ()
{
	echo "Enter a Python version with a single trailing digit: "
	echo -n -e "Ie. ${YL}\"2.7\"${NC} > "
	read v
	
	VERSION=$(awk -v FLOOR=2.0 -v CIEL=3.5 -v v=$v \
			  'BEGIN {if ((v>=FLOOR) && (v<=CIEL)) printf ("%s" , v); else printf ("%s" , "NULL");}')
	
	if [[ "$VERSION" == "NULL" ]]; then
		echo
		echo -e "${RED}This application does not currently support${NC}"
		echo -e "${RED}Python $v, if you believe it's important that${NC}"
		echo -e "${RED}version $v be supported, email: pswanson@ucdavis.edu${NC}"
		echo 
		custom_version
	fi
	
} #Allows user to custom select a Python version and validates recursively

choose_venv ()
{
	pick_version
	
	if [[ "$VERSION" -eq 1 ]]; then
		VERSION=`python -c "import sys;version='{info[0]}.{info[1]}'.format(info=list(sys.version_info[:2]));sys.stdout.write(version)";`
		create_venv $VERSION 
	elif [[ "$VERSION" -eq 2 ]]; then
		VERSION="2.7"
		create_venv $VERSION
	elif [[ "$VERSION" -eq 3 ]]; then
		VERSION="3.4" 
		create_venv $VERSION
	elif [[ "$VERSION" -eq 4 ]]; then
		VERSION="3.5"
		create_venv $VERSION
	elif [[ "$VERSION" -eq 5 ]]; then
		custom_version
		create_venv $VERSION
	fi
	
    echo
} # Choose a python virtual environment

get_pip_packages ()
{
    source $PWDIR/venv/bin/activate

	echo
    echo Installing pip packeges...
    echo

    pip install django~=1.9.2
	pip install s3cmd
	
	echo -e "${GREEN} Packages installed!${NC}"

} # Installs pertinent pip packages
# !! ADD: database files for postgres
# !! Potential ADD: good packages to use

create_app ()
{
    echo
    echo Creating Django Application $APPLNAME...
	
    django-admin startproject $APPLNAME 

    echo -e "${GREEN}Created project $APPLNAME!${NC}"
    echo
} # Creates the initial Django project

run_migrations ()
{
    echo Setting up application...
	
    cd $PWDIR/$APPLNAME
    python manage.py makemigrations
    python manage.py migrate
	
	echo -e "${GREEN}Migrations successful${NC}"
} # run initial migrations 

create_base ()
{
    echo
    echo Creating base...
	
    python manage.py startapp base
    cd base

	echo "from django.conf.urls import url" >> urls.py
	echo "from . import views" >> urls.py
	echo -e "\n\n\n" >> urls.py
	echo "urlpatterns = [" >> urls.py
	echo "    url(r'^$', views.base, name='base')," >> urls.py
	echo "]" >> urls.py
	
	rm -f views.py
	
	echo "from django.shortcuts import render" >> views.py
	echo -e "\n\n\n" >> views.py
	echo "def base(request):" >> views.py
	echo "    return render(request, 'base/home.html', {})" >> views.py

	cd $PWDIR/$APPLNAME/$APPLNAME
	rm -f urls.py
	
	echo "from django.conf.urls import include, url" >> urls.py
	echo "from django.contrib import admin" >> urls.py
	echo -e "\n\n\n" >> urls.py
	echo "urlpatterns = [" >> urls.py
	echo "    url(r'^admin/', admin.site.urls)," >> urls.py
	echo "    url(r'', include('base.urls'))," >> urls.py
	echo "]" >> urls.py
	
	rm -f settings.py
	cat <<EOT >> settings.py
"""
Django settings for $APPLNAME project.

Generated by 'django-admin startproject' using Django 1.9.9.

For more information on this file, see
https://docs.djangoproject.com/en/1.9/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/1.9/ref/settings/
"""

import os

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/1.9/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'k6mtaccd%_y%jtf2@jm0wp$@mj-vys3(7h(wvkdh%==kep&0)e'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = []


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
	'base'
]

MIDDLEWARE_CLASSES = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.auth.middleware.SessionAuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = '$APPLNAME.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = '$APPLNAME.wsgi.application'


# Database
# https://docs.djangoproject.com/en/1.9/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}


# Password validation
# https://docs.djangoproject.com/en/1.9/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/1.9/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/1.9/howto/static-files/

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static')


EOT

	cd $PWDIR/$APPLNAME/base
	mkdir templates
	mkdir static
	cd templates
	mkdir base
	cd base

	cat <<EOT >> base.html
{% load staticfiles %}
<html>
  <head>
    <title>Base</title>
    <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap-theme.min.css">
    <link href="https://fonts.googleapis.com/css?family=Baloo+Tamma" rel="stylesheet" type='text/css'>
    <link rel="stylesheet" href="{% static 'css/base.css' %}">
  </head>
  
  <body>
    <div class="header">
      <h1>Welcome to ClusterBomb!</h1>
    </div>
    <div class="content">
      <div class="row">
        <div class="col-md-8">
          {% block content %}
          {% endblock %}
        </div>
      </div>
    </div>
  </body>
 </html>
EOT

	cat <<EOT >> home.html
{% extends 'base/base.html' %}
{% block content %}
  <br><br><br><br>
  <div>
    <h1body>ClusterBomb setup complete!</h1body>
  </div>
  
{% endblock %}
EOT

	cd $PWDIR/$APPLNAME/base/static
	mkdir css
	cd css
	
	cat <<EOT >> base.css
h1{
    color: White;
    font-family: 'Baloo Tamma';
}

h1body{
    color: #373F51;
    font-family: 'Baloo Tamma';
	font-size: 4em;
	text-align: center;
	padding-left: 20px;
}

.header {
    background-color: #373F51;
	font-family: 'Baloo Tamma';
    margin-top: 0;
    padding: 20px 20px 20px 40px;
    font-size: 42pt;
    text-decoration: none;
}

body {
    background-color: White;
}
EOT

	echo -e "${GREEN}Created base!${NC}"


} # Sets up and creates a base template

run_detonate ()
{
	echo
	echo -e "${LBLU}Running Detonate.sh${NC}"
	cd $PWDIR
	./Detonate.sh
} # Runs Detonate.sh

run_custom_detonate ()
{
	echo -n -e "Enter arguments for Detonate ${YL}[ -n -d ]${NC} > "
	read DETARGS
	echo
	echo -e "${LBLU}Running Detonate.sh $DETARGS${NC}"
	cd $PWDIR
	Detonate.sh $DETARGS
} # Runs Detonate.sh

start_app ()
{
	cd $PWDIR/$APPLNAME
	echo 
	echo -e "${LBLU}Starting application...${NC}"
	
	python manage.py runserver
} # Starts the application server

custom ()
{
	name_app
	choose_venv
	get_pip_packages
	create_app
	run_migrations
	create_base
	
	if [[ "DETONATE" -eq 1 ]]; then
		run_custom_detonate
	else 
		start_app
	fi
	
	exit $?
} # Driver for custom application creation

default ()
{
	name_app
	create_venv $VERSION
	get_pip_packages
	create_app
	run_migrations
	create_base
	
	if [[ "$CDETONATE" -eq 1 ]]; then
		run_custom_detonate
	elif [[ "$DETONATE" -eq 1 ]]; then
		run_detonate
	else
		start_app
	fi
		
	exit $?
} # Driver for default application creation

invalid_arg ()
{
	echo -e "${RED}Argument $* is invalid! Exiting...${NC}"
	exit 0
} # Exits on invalid command line argument

cla_parser ()
{
	for ARGUMENT in "$@"
	do
		
		if [[ "$ARGUMENT" == -[^-]* ]]; then
			LENGTH=${#ARGUMENT}
			START=1
						
			while [ $START -lt $LENGTH ]
			do
				ARG="-${ARGUMENT:$START:1}"
				CLA+=("$ARG")	
				START=$[START+1]
			done
		
		elif [[ "$ARGUMENT" == --* ]]; then
			CLA+=("$ARGUMENT")
		
		else
			invalid_arg $ARGUMENT
		fi		
		
	done
	
} # Parses command line arguments and checks argument formatting

get_cla ()
{
	cla_parser $@
	
	for ARGUMENT in "${CLA[@]}"
	do
	
		if [[ "$ARGUMENT" == "-c" ]] || [[ "$ARGUMENT" == --custom ]]; then
			CUSTOM=1
		elif [[ "$ARGUMENT" == "-d" ]] || [[ "$ARGUMENT" == --dud ]]; then
			DETONATE=0
		elif [[ "$ARGUMENT" == "-a" ]] || [[ "$ARGUMENT" == --detargs ]]; then
			CDETONATE=1
		else
			invalid_arg $ARGUMENT
		fi
		
	done
} # Reads accepted command line arguments

main ()
{
	PWDIR=$(pwd)
	get_cla $@
	
	if [[ "$CUSTOM" -eq 0 ]]; then
		default
	else
		custom
	fi
} # Main ()
  # Gets arguments from command line and executes the installation based on
  # those arguments.  

main $@

