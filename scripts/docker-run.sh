#!/bin/bash
export PATH=$PATH:/docker/scripts
service mysql start
service nginx start

su - freeciv -c "cd /docker/scripts/ && start-freeciv-web.sh"

tail -f  /docker/logs/pbem.log /docker/logs/meta-stats.log /docker/logs/freeciv-earth.log
