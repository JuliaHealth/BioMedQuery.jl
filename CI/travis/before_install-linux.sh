#!/bin/bash

echo "------------------------------------------"
echo Running before_install-linux.sh...
echo "------------------------------------------"

# Install and start MySQL on OSX
echo ">>> apt-get install mysql"

# mysql client
sudo apt-get update\
    && apt-get install -y mysql-client libmysqlclient-dev

echo ">>> mysql.server start"
mysql.server start
