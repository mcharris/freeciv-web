#!/bin/bash

# Freeciv-web Docker Bootstrap Script - play.freeciv.org 
# 2015-09-12 - Andreas Rosdal
#
basedir="/docker"
logfile="/docker/freeciv-web-docker.log"

# Redirect copy of output to a log file.
exec > >(tee ${logfile})
exec 2>&1
set -e

echo "================================="
echo "Running Freeciv-web setup script."
echo "================================="

uname -a
echo basedir  $basedir
echo logfile $logfile

# User will need permissions to create a database
mysql_user="root"
mysql_pass=""

resin_version="4.0.44"
resin_url="http://www.caucho.com/download/resin-${resin_version}.tar.gz"
tornado_url="https://pypi.python.org/packages/source/t/tornado/tornado-4.2.1.tar.gz"
slimerjs_url="https://download.slimerjs.org/nightlies/0.10.0pre/slimerjs-0.10.0pre.zip"  
casperjs_url="https://github.com/n1k0/casperjs/archive/1.1-beta3.zip"


## Setup
mkdir -p ${basedir}
chmod -R 777 ${basedir}
cd ${basedir}

## dependencies
echo "==== Installing Updates and Dependencies ===="
export DEBIAN_FRONTEND=noninteractive
echo "mysql setup..."
mysql_install_db
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${mysql_pass}"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${mysql_pass}"


echo "==== Fetching/Installing Tornado Web Server ===="
cd /tmp
wget ${tornado_url}
tar xvfz tornado-4.2.1.tar.gz
cd tornado-4.2.1
python3 setup.py install

pip3 install wikipedia

## mysql setup
echo "==== Setting up MySQL ===="
service mysql start || cat /var/log/mysql/*.*

# configuration files
dos2unix ${basedir}/scripts/configuration.sh.dist
sed -e "s/MYSQL_USER=root/MYSQL_USER=${mysql_user}/" -e "s/MYSQL_PASSWORD=changeme/MYSQL_PASSWORD=${mysql_pass}/" ${basedir}/scripts/configuration.sh.dist > ${basedir}/scripts/configuration.sh
cp ${basedir}/publite2/settings.ini.dist ${basedir}/publite2/settings.ini

echo "==== Building freeciv ===="
dos2unix ${basedir}/freeciv/freeciv-web.project
cd ${basedir}/freeciv && ./prepare_freeciv.sh
cd freeciv && make install

echo "==== Building freeciv-web ===="
cd /var/lib/tomcat8 && sudo chmod -R 777 webapps logs && setfacl -d -m g::rwx webapps && sudo chown -R www-data:www-data webapps/
cd ${basedir}/scripts/freeciv-img-extract/ && ./setup_links.sh && ./sync.sh
cd ${basedir}/scripts && ./sync-js-hand.sh
cd ${basedir}/freeciv-web && sudo ./setup.sh

echo "=============================="

service nginx stop
rm /etc/nginx/sites-enabled/default
cp ${basedir}/publite2/nginx.conf /etc/nginx/

mkdir -p ${basedir}/logs
chmod 777 ${basedir}/logs

echo "Freeciv-web installed."
