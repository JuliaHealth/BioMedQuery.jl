#!/bin/sh -f
#
# For useful information on loading your Semantic Network files
# into a MySQL database, please consult the on-line
# documentation at:
#
# http://www.nlm.nih.gov/research/umls/load_scripts.html
#

#
# Database connection parameters
# Please edit these variables to reflect your environment
#
MYSQL_HOME=<path to MYSQL_HOME>
user=<username>
password=<password>
db_name=<db_name>

/bin/rm -f mysql_net.log
touch mysql_net.log
ef=0

echo "See mysql_net.log for output"
echo "----------------------------------------" >> mysql_net.log 2>&1
echo "Starting ... `/bin/date`" >> mysql_net.log 2>&1
echo "----------------------------------------" >> mysql_net.log 2>&1
echo "MYSQL_HOME = $MYSQL_HOME" >> mysql_net.log 2>&1
echo "user =       $user" >> mysql_net.log 2>&1
echo "db_name =    $db_name" >> mysql_net.log 2>&1

echo "    Create and load tables ... `/bin/date`" >> mysql_net.log 2>&1
$MYSQL_HOME/bin/mysql -vvv -u $user -p$password $db_name < mysql_net_tables.sql >> mysql_net.log 2>&1
if [ $? -ne 0 ]; then ef=1; fi


echo "----------------------------------------" >> mysql_net.log 2>&1
if [ $ef -eq 1 ]
then
echo "There were one or more errors.  Please reference the mysql_net.log file for details." >> mysql_net.log 2>&1
else
echo "Completed without errors." >> mysql_net.log 2>&1
fi
echo "Finished ... `/bin/date`" >> mysql_net.log 2>&1
echo "----------------------------------------" >> mysql_net.log 2>&1
