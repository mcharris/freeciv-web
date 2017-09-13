#!/bin/bash
export PATH=$PATH:/docker/scripts
service mysql start
service nginx start
cd /docker/scripts/
sudo -u freeciv ./start-freeciv-web.sh
