#!/bin/bash

#$1 is iso
#$2 is name for piggyback data

if [ "$#" -ne 2 ]
then
  echo "Usage: recoverPiggyBackData.sh <device or iso file> <name of file to save data to>"
  exit 1
fi

size=`isosize $1`
blocks=`expr $size / 2048`


#write out piggy back using dd
dd if=$1 bs=2048 skip=$blocks of=$2

echo "done!"
echo "`ls -l $2`"
