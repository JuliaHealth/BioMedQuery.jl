#!/bin/bash

echo "------------------------------------------"
echo Running before_install-osx.sh...
echo "------------------------------------------"

# Install and start MySQL on OSX
echo ">>> brew install mysql"
brew update
brew install mysql
echo ">>> mysql.server start"
mysql.server start
