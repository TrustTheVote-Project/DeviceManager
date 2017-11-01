#!/bin/sh

#source in strings
. ../resources/electOSStrings.txt

CONFIGFILE=/tmp/cbcConfig.json

# temporary file
TEMP=/tmp/answer$$

DLG=/usr/bin/dialog
configType="ElectOS-CBC-v${VERSION}"
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
input=$( $DLG --title "$CBC_CONFIG" --output-separator ":" \
	--ok-label "Submit"  --mixedform "" 20 50 0 \
        "$CBC_CONFIG_TYPE"    1 1    "${configType}"  1 20  0 0 2 \
        "$CBC_CONFIG_DATE"    2 1    "${configDate}"  2 20  0 0 2 \
        "$CBC_CONFIG_NAME"    3 1    "$configName"    3 20  20 0 0 \
        "$CBC_LOG_LEVEL"      4 1    "$logLevel"      4 20  20 0 0  2>&1 1>&3)
if [[ $? != 0 ]]
then
    exit
fi
IFS=":" read configName logLevel <<< $input

continue=0

#validate required fields and formats
if [[ !($logLevel =~ $logLevelRE) ]] 
then
    $DLG --msgbox "$CBC_LOG_LEVEL_MUST_BE_A_NUMBER" 8 20
else
    continue=$(($continue+1))
fi
if [[ !($configName =~ $configNameRE) ]] 
then
    $DLG --msgbox "$CBC_CONFIG_NAME_REQUIRED" 6 20
else
    continue=$(($continue+1))
fi
done

input2=$($DLG --no-tags --output-separator ":" \
	--checklist  "$CBC_CHECK_OR_UNCHECK" 12 40 1 \
	"retainBallotImages" "$CBC_RETAIN_BALLOT_IMAGES" on \
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
#get these again... the CONFIRM_VALUES variable has variables itself, which were
#empty the first time the file was sourced
. ../resources/electOSStrings.txt

  $DLG --yesno "$CBC_CONFIRM_VALUES" 30 60

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
