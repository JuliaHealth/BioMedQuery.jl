#!/bin/bash

email=$1
username=$2
password=$3
in_file=$4
out_file=$5

./IIWebAPI/SKR_Web_API_V2_3/run.sh GenericBatchCustom --email $email $in_file --username $username --password $password > $out_file
