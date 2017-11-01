#!/bin/sh

#source in strings
. ../resources/electOSStrings.txt

CONFIGFILE=/tmp/tabulatorConfig.json

# temporary file
TEMP=/tmp/answer$$

DLG=/usr/bin/dialog
vtdCount=442
configType="ElectOS-Tabulator-v${VERSION}"
configDate="`date +\"%x %X\"`"

getTabConfigInfo () {

vtdCountRE='^[0-9]+$'
tallyCountRE='^[0-9]*$'
configNameRE='^[a-zA-Z0-9_ .-]+$'
exec 3>&1

continue=0

#require numerics for the counts 
until [[ ($vtdCount =~ $vtdCountRE) && ($tallyCount =~ $tallyCountRE) && ($configName =~ $configNameRE) && ($continue == 3) ]] 
do
input=$( $DLG --title "$TAB_CONFIG" --output-separator ":" \
	--ok-label "Submit"  --mixedform "" 20 50 0 \
        "$TAB_CONFIG_TYPE"    1 1    "${configType}" 1 20 0 0 2 \
        "$TAB_CONFIG_DATE"    2 1    "${configDate}"  2 20  0 0 2 \
        "$TAB_CONFIG_NAME"    3 1    "${configName}"  3 20  20 0 0 \
        "$TAB_VTD_COUNT"      4 1    "${vtdCount}"  4 20  20 0 0 \
        "$TAB_TALLY_COUNT"    5 1    "${tallyCount}"  5 20  20 0 0 2>&1 1>&3)

if [[ $? != 0 ]]
then
    exit
fi
IFS=":" read configName vtdCount tallyCount <<< $input
continue=0

#validate required fields and formats
if [[ !($vtdCount =~ $vtdCountRE) ]] 
then
    $DLG --msgbox "$TAB_VTD_MUST_BE_A_NUMBER" 6 20
else
    continue=$(($continue+1))
fi
if [[ !($tallyCount =~ $tallyCountRE) ]] 
then
    $DLG --msgbox "$TAB_TALLY_COUNT_MUST_BE_A_NUMBER" 6 30
else
    continue=$(($continue+1))
fi
if [[ !($configName =~ $configNameRE) ]] 
then
    $DLG --msgbox "$TAB_CONFIG_NAME_REQUIRED" 6 20
else
    continue=$(($continue+1))
fi
done

input2=$($DLG --no-tags --output-separator ":" \
	--checklist  "$TAB_CHECK_UNCHECK" 12 40 2 \
	"RequireAllTallies" "$TAB_REQUIRE_ALL_TALLIES" on \
	"RequireVTDs" "$TAB_REQUIRE_VTDS" on 2>&1 1>&3)

checklistRE1='^\s*:(.*):(.*)$'
checklistRE2='^\s*:RequireVTDs$'
checklistRE3='^\s*:(.*)$'

if [[ $input2 =~ $checklistRE1 ]]
then
    input2="${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
else 
    if [[ $input2 =~ $checklistRE2 ]] 
    then
	echo
	#do nothing  - we're dealing with ":RequireVTDs", nothing to do
    else 
        if [[ $input2 =~ $checklistRE3 ]] 
	then
	    #we have :RequireAllTallies...that should be "RequireAllTallies:"
            input2="${BASH_REMATCH[1]}:"
	else 
            $DLG --msgbox "$TAB_INPUT_DIDNT_MATCH_REGEX" 10 40
	fi
    fi
fi

IFS=":" read  requireAll requireVTD <<< $input2
if [[ $requireVTD == '' ]] 
then
    requireVTD="off"
else 
    requireVTD="on"
fi

if [[ $requireAll == '' ]] 
then
    requireAll="off"
else
    requireAll="on"
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
  $DLG --yesno "$TAB_CONFIRM_VALUES" 30 60

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
cat << EOF > $CONFIGFILE
{"configType" : "$configType", "configDate" : "$configDate", "configName" : "$configName", "vtdCount" : "$vtdCount", "tallyCount" : "$tallyCount", "requireVTD": "$requireVTD", "requireAll" : "$requireAll"}
EOF
}

rc=0
while [[ $rc != 1 ]]
do
getTabConfigInfo
rc=$?
done
writeJSONConfigFile
