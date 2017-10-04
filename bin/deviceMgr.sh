#!/bin/sh

OSETHOME="/opt/OSET"
cd ${OSETHOME}/bin

VER=`cat electOS.ver`
EXTRADATAFILE=/tmp/extraDataFile.tgz
EDFFILE=""
EDFXSD="$OSETHOME/bin/NIST_V1_election_resultsV50.xsd"
TABCONFIGFILE=/tmp/tabulatorConfig.json
PBCCONFIGFILE=/tmp/pbcConfig.json
CBCCONFIGFILE=/tmp/cbcConfig.json
TABBASEISO=${OSETHOME}/ISO/OSET-Tab-${VER}.iso
CBCBASEISO=${OSETHOME}/ISO/OSET-CBC-${VER}.iso
PBCBASEISO=${OSETHOME}/ISO/OSET-PBC-${VER}.iso


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
    $DLG --yesno "You have already created the configuration file for the Tabulator.  Would you like to make a copy of the Tabulator ISO?" 10 40
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
    $DLG --yesno "You have already created the configuration file for the Central Ballot Counter.  Would you like to make a copy of the CBC ISO?" 10 40
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
    $DLG --yesno "You have already created the configuration file for the Precinct Ballot Counter.  Would you like to make a copy of the PBC ISO?" 10 40
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
EDFFILE=$(dialog --title "Please select an Election Definition file..." --stdout --fselect /dev/sr0 14 48)

if [[ $? != 0 ]]
then
    exit
fi

if [[ "$EDFFILE" != "" ]] 
then
    #is the file valid??
    #/usr/bin/xmllint --noout --schema $EDFXSD --valid $EDFFILE &> /dev/null
    xmllintrc=$(/usr/bin/xmllint --noout --nonet $EDFFILE &> /dev/null ; echo $?)
    $DLG --pause "Validating the Election Data File..." 10 40 1
    if [[ $xmllintrc != 0 ]]
    then
	#uh-oh...
        $DLG --msgbox "The selected Election Data File appears to have some validation errors.  Please correct those and retry." 10 40
	unset EDFFILE
    else 
	cp $EDFFILE /tmp
        EDFFILE=/tmp/`basename $EDFFILE`
$DLG --msgbox "the EDFFILE is now $EDFFILE" 10 40
    fi

fi
}


buildCBC () {
#
#$DLG --timeout 5 --msgbox "Building the Central Ballot Counter ISO" 10 40

#we need data for the CBC...
#FILE=$(dialog --title "Select an Election Definition file..." --stdout --fselect /tmp/ 14 48)
#$DLG --title "Select an Election Definition File..." --stdout --fselect / 10 40 2>$TEMP
#echo `cat $TEMP`

#$DLG --timeout 5 --msgbox "Creating the Central Ballot Counter with $FILE" 10 40

#for i in $(seq 0 10 100) ; do sleep 1; echo $i | $DLG --gauge "Writing DVD..." 10 70 0; done

#$DLG --timeout 5 --msgbox "DVD successfully created, please remove it, label it properly, and store it SECURELY!" 10 40

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
#
#$DLG --timeout 5 --msgbox "Building the Precinct Ballot Counter ISO" 10 40
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
$DLG --menu \
	"Select a Disc to create..." 12 60 4\
    "1" "Central Ballot Counter" \
    "2" "Tabulator" \
    "3" "Precinct Ballot Counter" \
    "4" "Exit" 2>$TEMP

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

$DLG --timeout 5 --msgbox "Welcome to the ElectOS Device Manager! \n\nversion $VER\nOSET Foundation\nCopyright 2017" 10 40

while [[ "$EDFFILE" == "" ]]
do
    getEDF
done
while true
do
  main_menu
done

