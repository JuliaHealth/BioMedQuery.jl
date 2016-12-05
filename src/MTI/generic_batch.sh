#!/bin/bash

email=$1
in_file=$2
out_file=$3

echo $email

./IIWebAPI/SKR_Web_API_V2_3/run.sh GenericBatchNew --email $email $in_file > $out_file
