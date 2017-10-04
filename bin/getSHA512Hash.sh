#!/bin/bash

#$1 is the file or device
if [ "$#" -ne 1 ]
then
  echo "Usage: getSHA512Hash.sh <device or iso file>"
  exit 1
fi

blocks=`isosize $1`
count=`expr $blocks / 2048`
echo $count
dd if=$1 bs=2048 count=$count | sha512sum 
