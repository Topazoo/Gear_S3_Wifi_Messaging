sudo apt-get update
sudo apt-get install python-pip python-dev build-essential 
pip install --upgrade pip
pip2 install --upgrade pip
pip2 install --upgrade pip2
pip2 install virtualenv
sudo pip install virtualenv
sudo pip2 install virtualenv
ls
git init
git remote add origin https://github.com/Topazoo/Gear_S3_Wifi_Messaging.git
git pull origin master
ls
cd server
ls
cd dispatch
ls
sudo ufw allow 8000
virtualenv env
source env/bin/activate
ls
pip install gunicorn
pip install django==1.9.13
pip install nginx
sudo apt-get install nginx
./manage.py runserver 0.0.0.0:8000
sudo nano config.ini
ls
cd ..
ls
cd dispatch
ls
./manage.py runserver 0.0.0.0:8000
gunicorn --bind 0.0.0.0:8000 mydispatch.wsgi:application
sudo pip install gunicorn
sudo pip2 install gunicorn
gunicorn --bind 0.0.0.0:8000 mydispatch.wsgi:application
sudo gunicorn --bind 0.0.0.0:8000 mydispatch.wsgi:application
sudo gunicorn --bind 0.0.0.0:8000 dispatch.wsgi:application
gunicorn --bind 0.0.0.0:8000 dispatch.wsgi:application
sudo nano /etc/systemd/system/gunicorn.service
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl status gunicorn
ls
sudo nano /etc/nginx/sites-available/myproject
sudo ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled
sudo ln -s /etc/nginx/sites-available/dispatch /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl enable gunicorn
sudo mv /etc/nginx/sites-available/myproject /etc/nginx/sites-available/dispatch
sudo rm /etc/nginx/sites-available/myproject
sudo rm /etc/nginx/sites-enabled/myproject
sudo ln -s /etc/nginx/sites-available/dispatch /etc/nginx/sites-enabled
sudo rm /etc/nginx/sites-enabled/dispatch
sudo ln -s /etc/nginx/sites-available/dispatch /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx
sudo ufw delete allow 8000
sudo ufw allow 'WWW'
sudo ufw allow 'www'
sudo systemctl restart gunicorn
sudo systemctl restart nginx
sudo journalctl -u gunicorn
sudo journalctl -u nginx
sudo mkdir /etc/systemd/system/nginx.service.d
sudo su
sudo systemctl restart nginx
sudo journalctl -u gunicorn
sudo systemctl restart gunicorn
sudo journalctl -u gunicorn
sudo journalctl -u nginx
sudo journalctl -u gunicorn
sudo journalctl -u nginx
cd /var/log
ls
cd nginx
ls
cat error.log
sudo nano /etc/nginx/sites-available/dispatch
sudo systemctl restart gunicorn
sudo systemctl restart nginx
ls
cat error.log
cd ..
ls
cd ..
cd /home/ubuntu
ls
sudo journalctl -u gunicorn
ls
cd server
ls
cd *
ls
cd env
ls
cd lib
ls
cd ..
cd bin
ls
cd ..
ls
cd local
ls
cd /var/log
ls
cd syslog
cat syslog
cd /home/*/*/*
ls
nano config.ini
sudo systemctl restart gunicorn
cat /var/logs/syslog
cat /var/log/syslog
sudo systemctl restart gunicorn
cat /var/log/syslog
nano config.ini
sudo systemctl restart gunicorn
sudo journalctl -u gunicorn
sudo systemctl restart gunicorn
sudo journalctl -u gunicorn
