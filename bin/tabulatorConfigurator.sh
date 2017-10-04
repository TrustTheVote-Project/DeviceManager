#!/bin/sh

VER=`cat electOS.ver`
CONFIGFILE=/tmp/tabulatorConfig.json

# temporary file
TEMP=/tmp/answer$$

DLG=/usr/bin/dialog
vtdCount=442
configType="ElectOS-Tabulator-v${VER}"
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
input=$( $DLG --title "Tabulator Configuration" --output-separator ":" \
	--ok-label "Submit"  --mixedform "" 20 50 0 \
        "Configuration Type  :" 1 1 "${configType}" 1 20 0 0 2 \
        "Configuration Date  :"      2 1    "${configDate}"  2 20  0 0 2 \
        "Configuration Name  :"      3 1    "$configName"  3 20  20 0 0 \
        "VTD Count           :"      4 1    "$vtdCount"  4 20  20 0 0 \
        "Tally Count         :"      5 1    "$tallyCount"  5 20  20 0 0 2>&1 1>&3)  
if [[ $? != 0 ]]
then
    exit
fi
IFS=":" read configName vtdCount tallyCount <<< $input

#validate required fields and formats
if [[ !($vtdCount =~ $vtdCountRE) ]] 
then
    $DLG --msgbox "VTD Count must be a number." 6 20
else
    continue=$(($continue+1))
fi
if [[ !($tallyCount =~ $tallyCountRE) ]] 
then
    $DLG --msgbox "Tally Count must be a number if provided." 6 30
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
	--checklist  "Check or uncheck as needed:" 12 40 2 \
	"RequireAllTallies" "Require all Tallies"  on \
	"RequireVTDs" "Require VTDs" on 2>&1 1>&3)

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
            $DLG --msgbox "input didn't match regex!" 10 40
	fi
    fi
fi

#$DLG --msgbox "input is **NOW** '$input2' " 10 40

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
  $DLG --yesno "Please confirm the following values.  Select Yes to confirm, select No to change the values.  If the values are wrong and you continue, you will *NOT* be able to change the values for this tool without completely restarting the Device Manager and starting from scratch.\n\n\nConfiguration Type:	$configType\nConfiguration Date:	$configDate\nConfiguration Name:	$configName\nVTD Count:		$vtdCount\nTally Count:		$tallyCount\nRequire all VTDs:	$requireVTD\nRequire All Tallies:	$requireAll\n\n\nAre these values correct?"  30 60

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

#$DLG --timeout 5 --msgbox "Welcome to the ElectOS Tabulator!\n\nversion $VER\nOSET Foundation\nCopyright 2017" 10 40 
rc=0
while [[ $rc != 1 ]]
do
getTabConfigInfo
rc=$?
done
writeJSONConfigFile
