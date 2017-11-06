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
XPATH=/usr/bin/xpath
defaultTallyCount=0

#--------------------------------------------------------------
createExtraDataFile() {

  if [[ "$1" == "tab" ]] 
  then
     tar zcf $EXTRADATAFILE $EDFFILE $TABCONFIGFILE &>/dev/null | $DLG --progressbox "$DM_WORKING_ON_THAT" 10 50
     BASEISO=$TABBASEISO
  elif [[ "$1" == "pbc" ]]
  then
     tar zcf $EXTRADATAFILE $EDFFILE $PBCCONFIGFILE &>/dev/null| $DLG --progressbox "$DM_WORKING_ON_THAT" 10 50
     BASEISO=$PBCBASEISO
  elif [[ "$1" == "cbc" ]]
  then
     tar zcf $EXTRADATAFILE $EDFFILE $CBCCONFIGFILE &>/dev/null| $DLG --progressbox "$DM_WORKING_ON_THAT" 10 50
     BASEISO=$CBCBASEISO
  fi
}

buildISO() {
  createExtraDataFile $1
  cat $BASEISO $EXTRADATAFILE > /tmp/`basename $BASEISO`
}

burnISO() {
    $DLG --yesno "$DM_BURN_NOW" 10 40
    if [[ $? == 0 ]]
    then
       $DLG --yes-label OK --no-label Cancel --yesno "$DM_INSERT_DISC" 10 40
       if [[ $? == 0 ]]
       then
	  #if env variable DM_FAKE_BURN is set, just fake it - don't burn
	  #and take a ton of time - great for demos
	  if [ ! -z ${DM_FAKE_BURN+x} ]
	  then
	     #for testing/demoing
	     $DLG --no-ok --no-cancel --pause "pseudo-burning disc..."  7 25 5
	  else 
	     #burn, baby, burn! ;-)
	     #OK, one more way to go through the motions and keep from wasting
	     #DVDs... set DM_DUMMY_BURN to something and this won't really
	     #burn anything
	     if [ -z ${DM_DUMMY_BURN+x} ]
             then
		DUMMY=""
	     else 
		DUMMY='--dummy'
             fi
	     wodim -v speed=2 dev=/dev/sr0 $DUMMY -dao /tmp/`basename $BASEISO` 2>&1 | $DLG --progressbox 15 75
	  fi
       else 
	  return
       fi
    else 
       return
    fi
}

getTallyCount () {

    defaultTallyCount=$($XPATH -q -e 'count(/ElectionReport/GpUnitCollection/GpUnit/Type/text()[. = "precinct"])' $EDFFILE)

}

getTabConfigInfo () {

if [[ -e $TABCONFIGFILE ]] 
then
    $DLG --yesno "$DM_ALREADY_CREATED_TAB" 10 40
else 
    getTallyCount
    ./tabulatorConfigurator.sh $defaultTallyCount
fi
return $?
}

getCBCConfigInfo () {
if [[ -e $CBCCONFIGFILE ]] 
then
    $DLG --yesno "$DM_ALREADY_CREATED_CBC" 10 40
else 
    ./cbcConfigurator.sh
fi
return $?
}


getPBCConfigInfo () {
if [[ -e $PBCCONFIGFILE ]] 
then
    $DLG --yesno "$DM_ALREADY_CREATED_PBC" 10 40
else 
    ./pbcConfigurator.sh
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

    $(/usr/bin/xmllint --nowarning --noout --nonet $EDFFILE; echo $? > /tmp/rcfile ) | $DLG --progressbox "$DM_VALIDATING_EDF" 10 40
    xmllintrc=`cat /tmp/rcfile`

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
   burnISO
fi
}

buildTabulator() {

getTabConfigInfo
if [[ $? == 0 ]]
then
   buildISO tab 
   burnISO
fi

}

buildPrecinctBallotCounter() {

getPBCConfigInfo
if [[ $? == 0 ]]
then
   buildISO pbc 
   burnISO
fi

}

# clean up and exit
cleanUp() {
  clear
  rm -f /tmp/answer*
  rm -f /tmp/rcfile
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
rm -f /tmp/rcfile
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

