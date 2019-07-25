#!/bin/bash

echo "------------------------------------------"
echo Running before_install-osx.sh...
echo "------------------------------------------"

# Install and start MySQL on OSX
echo ">>> brew install mariadb"
brew update
brew install mariadb

echo ">>> configure mariadb"
echo "[mysqld]" > $HOME/.my.cnf
echo "secure_file_priv = \"\" ">> $HOME/.my.cnf
echo "default_authentication_plugin = mysql_native_password" >> $HOME/.my.cnf
echo "local_infile = 1" >> $HOME/.my.cnf

echo ">>> mysql.server start"
mysql.server start
