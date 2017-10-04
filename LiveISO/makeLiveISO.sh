#!/bin/bash

if [ "$#" -ne 1 ]
then
   echo "Usage: makeLiveISO.sh [dm|tab|cbc|pbc]"
   exit 1
fi


VER=`cat /opt/OSET/bin/electOS.ver`

if [ "$1" == "tab" ]
then
    ISONAME=OSET-Tab-${VER}.iso
    KICKSTART=flat-fedora-live-minimal-tab.ks

elif [ "$1" == "cbc" ]
then
    ISONAME=OSET-CBC-${VER}.iso
    KICKSTART=flat-fedora-live-minimal-cbc.ks

elif [ "$1" == "pbc" ]
then
    ISONAME=OSET-PBC-${VER}.iso
    KICKSTART=flat-fedora-live-minimal-pbc.ks
elif [ "$1" == "dm" ]
then
    ISONAME=OSET-DM-${VER}.iso
    KICKSTART=flat-fedora-live-minimal-dm.ks
    #don't keep the last one around since everything in /opt/OSET/ISO gets pulled
    #into this ISO, which would bloat it unnecessarily
    rm /opt/OSET/ISO/${ISONAME}
else
    echo "Unknown option '$1' - exiting"
    exit 1
fi

cd /opt/OSET/LiveISO
sudo setenforce 0
sudo  livemedia-creator --make-iso --no-virt --iso-only --iso-name ${ISONAME} --releasever 26 --project Fedora --ks ${KICKSTART} 
sudo setenforce 1
