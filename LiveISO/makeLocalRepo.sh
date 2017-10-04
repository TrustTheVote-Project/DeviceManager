#!/bin/sh

OSETRPMDir=/opt/OSET/rpmRepo
mkdir -p $OSETRPMDir

# verify all tools available
if [ ! -f /usr/bin/yumdownloader ] ; then
  echo This script requires that the yum-utils package be installed
  exit 1
fi
if [ ! -f /usr/bin/mkisofs ] ; then
  echo This script requries that the genisoimage package be installed
  exit 1
fi

# download RPMS
cd $OSETRPMDir
#for pkg in `rpm -qa | sort` ; do
for pkg in `cat /opt/OSET/LiveISO/packageList.txt`; do
  char=${pkg:0:1}
  
  #ignore commented packages or groups or removals
  if [[ $char != '@' && $char != "-" && $char != '#' ]] ; then
	  if [ ! -f $pkg.rpm ] ; then
	    #this could be slightly more efficient... check for existence of each sub
	    #package before blindly downloading them all
	    echo Downloading $pkg
	    repotrack -t ${OSETRPMDir} -a `uname -m` $pkg >& /dev/null
	    #yumdownloader -y --resolve $pkg >& /dev/null
	    if [ $? -ne 0 ] ; then
	      echo ERRRO: unable to download $pkg
	    fi
	  else
	    echo $pkg already downloaded
	  fi
  else 
    echo Skipping $pkg
  fi
done
echo Indexing the Repo...
createrepo .
chown -R lighttpd:lighttpd .
chmod -R 755 .
cd ..

# prepare CD image
#mkisofs -J -R -o rpmCD.iso rpmCD

# EOF
