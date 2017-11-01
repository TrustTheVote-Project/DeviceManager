#!/bin/sh

OSETHOME="/opt/OSET"
cd ${OSETHOME}/bin

#source in strings
. ../resources/electOSStrings.txt
EXTRADATAFILE=/tmp/extraDataFile.tgz
EDFFILE=""
EDFXSD="$OSETHOME/bin/NIST_V1_election_resultsV50.xsd"
TABCONFIGFILE=/tmp/tabulatorConfig.json
PBCCONFIGFILE=/tmp/pbcConfig.json
CBCCONFIGFILE=/tmp/cbcConfig.json
TABBASEISO=${OSETHOME}/ISO/OSET-Tab-${VERSION}.iso
CBCBASEISO=${OSETHOME}/ISO/OSET-CBC-${VERSION}.iso
PBCBASEISO=${OSETHOME}/ISO/OSET-PBC-${VERSION}.iso


# temporary file
TEMP=/tmp/answer$$

DLG=/usr/bin/dialog
#--------------------------------------------------------------
createExtraDataFile() {

  if [[ "$1" == "tab" ]] 
  then
     tar zcf $EXTRADATAFILE $EDFFILE $TABCONFIGFILE &>/dev/null
     BASEISO=$TABBASEISO
  elif [[ "$1" == "pbc" ]]
  then
     tar zcf $EXTRADATAFILE $EDFFILE $PBCCONFIGFILE &>/dev/null
     BASEISO=$PBCBASEISO
  elif [[ "$1" == "cbc" ]]
  then
     tar zcf $EXTRADATAFILE $EDFFILE $CBCCONFIGFILE &>/dev/null
     BASEISO=$CBCBASEISO
  fi
}

buildISO() {
  createExtraDataFile $1
  cat $BASEISO $EXTRADATAFILE > /tmp/`basename $BASEISO`
}

burnISO() {
echo

}

getTabConfigInfo () {

if [[ -e $TABCONFIGFILE ]] 
then
    $DLG --yesno "$DM_ALREADY_CREATED_TAB" 10 40
    if [[ $? != 0 ]]
    then
       return
    fi
else 
    ./tabulatorConfigurator.sh
fi
return $?
}

getCBCConfigInfo () {
if [[ -e $CBCCONFIGFILE ]] 
then
    $DLG --yesno "$DM_ALREADY_CREATED_CBC" 10 40
    if [[ $? != 0 ]]
    then
       return
    fi
else 
    ./cbcConfigurator.sh
fi
return $?
}


getPBCConfigInfo () {
if [[ -e $PBCCONFIGFILE ]] 
then
    $DLG --yesno "$DM_ALREADY_CREATED_PBC" 10 40
    if [[ $? != 0 ]]
    then
       return
    fi
else 
    ./pbcConfigurator.sh
fi
if [[ $? == 0 ]]
then
   buildISO pbc 
  #dialog to user to put a blank DVD in
  #burn DVD
fi
return $?
}

getEDF() {

#we need an EDF for all ISO creation
EDFFILE=$(dialog --title "$DM_SELECT_EDF" --stdout --fselect /dev/sr0 14 48)

if [[ $? != 0 ]]
then
    exit
fi

if [[ "$EDFFILE" != "" ]] 
then
    #is the file valid??
    #/usr/bin/xmllint --noout --schema $EDFXSD --valid $EDFFILE &> /dev/null
    xmllintrc=$(/usr/bin/xmllint --noout --nonet $EDFFILE &> /dev/null ; echo $?)
    $DLG --pause "$DM_VALIDATING_EDF" 10 40 1
    if [[ $xmllintrc != 0 ]]
    then
	#uh-oh...
        $DLG --msgbox "$DM_VALIDATION_ERRORS" 10 40
	unset EDFFILE
    else 
	cp $EDFFILE /tmp
        EDFFILE=/tmp/`basename $EDFFILE`
#$DLG --msgbox "the EDFFILE is now $EDFFILE" 10 40
    fi

fi
}


buildCBC () {

getCBCConfigInfo
if [[ $? == 0 ]]
then
   buildISO cbc 
  #dialog to user to put a blank DVD in
  #burn DVD
fi
}

buildTabulator() {

getTabConfigInfo
if [[ $? == 0 ]]
then
   buildISO tab 
  #dialog to user to put a blank DVD in
  #burn DVD
fi

}

buildPrecinctBallotCounter() {

getPBCConfigInfo
if [[ $? == 0 ]]
then
   buildISO pbc 
  #dialog to user to put a blank DVD in
  #burn DVD
fi

}

# clean up and exit
cleanUp() {
  clear
  rm -f /tmp/answer*
  rm -f /tmp/*Config.json
  rm -f $EDFFILE
  rm -f /tmp/*.iso
  rm -f ${EXTRADATAFILE}
  exit
}

main_menu() {
$DLG --menu "$DM_SELECT_TOOL" 12 60 4 1 "$DM_CBC"  2 "$DM_TAB"  3 "$DM_PBC"  4 "$DM_EXIT" 2>$TEMP

if [[ $? != 0 ]]
then
    cleanUp
fi


  choice=`cat $TEMP`
  case $choice in
    1) buildCBC;;
    2) buildTabulator;;
    3) buildPrecinctBallotCounter;;
    4) cleanUp;;
  esac
}

#clean up from last run if necessary
rm -f /tmp/answer*
rm -f /tmp/*Config.json
rm -f /tmp/*.xml
rm -f /tmp/*.iso
rm -f ${EXTRADATAFILE}

$DLG --timeout 5 --msgbox "$DM_WELCOME" 10 40

while [[ "$EDFFILE" == "" ]]
do
    getEDF
done
while true
do
  main_menu
done

