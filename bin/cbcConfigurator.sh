#!/bin/sh

VER=`cat electOS.ver`
CONFIGFILE=/tmp/cbcConfig.json

# temporary file
TEMP=/tmp/answer$$

DLG=/usr/bin/dialog
configType="ElectOS-CBC-v${VER}"
configDate="`date +\"%x %X\"`"

getCBCConfigInfo () {

logLevelRE='^[1-5]$'
configNameRE='^[a-zA-Z0-9_ .-]+$'
exec 3>&1

#default log level
logLevel=5

continue=0

#require numerics for the counts 
until [[ ($logLevel =~ $logLevelRE) && (configName =~ $configNameRE) && ($continue == 2) ]] 
do
input=$( $DLG --title "CBC Configuration" --output-separator ":" \
	--ok-label "Submit"  --mixedform "" 20 50 0 \
        "Configuration Type  :" 1 1 "${configType}" 1 20 0 0 2 \
        "Configuration Date  :"      2 1    "${configDate}"  2 20  0 0 2 \
        "Configuration Name  :"      3 1    "$configName"  3 20  20 0 0 \
        "Log Level 	     :"      4 1    "$logLevel"  4 20  20 0 0 \
		 2>&1 1>&3)
if [[ $? != 0 ]]
then
    exit
fi
IFS=":" read configName logLevel <<< $input

continue=0

#validate required fields and formats
if [[ !($logLevel =~ $logLevelRE) ]] 
then
    $DLG --msgbox "Log Level must be a number from 1 to 5." 8 20
else
    continue=$(($continue+1))
fi
if [[ !($configName =~ $configNameRE) ]] 
then
    $DLG --msgbox "Config Name is required." 6 20
else
    continue=$(($continue+1))
fi
done

input2=$($DLG --no-tags --output-separator ":" \
	--checklist  "Check or uncheck as needed:" 12 40 1 \
	"retainBallotImages" "Retain Ballot Images" on \
	2>&1 1>&3)

re1=".*retainBallotImages.*"
if [[ $input2 =~ $re1 ]] 
then
    retainBallotImages="on"
else 
    retainBallotImages="off"
fi

# close fd
exec 3>&-


confirmSettings
return $?
}

confirmSettings() {
  $DLG --yesno "Please confirm the following values.  Select Yes to confirm, select No to change the values.  If the values are wrong and you continue, you will *NOT* be able to change the values for this tool without completely restarting the Device Manager and starting from scratch.\n\n\nConfiguration Type:	$configType\nConfiguration Date:	$configDate\nConfiguration Name:	$configName\nLog Level:		$logLevel\nRetain Ballot Images:	$retainBallotImages\n\n\nAre these values correct?"  30 60

#ok is zero
if [[ $? == 0 ]]
then
  #user pressed OK (0)
  return 1
else 
  return 0
fi
}

writeJSONConfigFile() {
echo $requireVTD
cat << EOF > $CONFIGFILE
{"configType" : "$configType", "configDate" : "$configDate", "configName" : "$configName", "logLevel" : "$logLevel", "retainBallotImages" : "$retainBallotImages"}
EOF
}

rc=0
while [[ $rc != 1 ]]
do
getCBCConfigInfo
rc=$?
done
writeJSONConfigFile
