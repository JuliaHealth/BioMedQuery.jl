#!/bin/bash

echo "------------------------------------------"
echo Running before_install-osx.sh...
echo "------------------------------------------"

# Install and start MySQL on OSX
echo ">>> brew install mariadb"
brew update
brew install mariadb
echo ">>> mysql.server start"
mysql.server start
