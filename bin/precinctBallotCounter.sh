#!/bin/sh

# temporary file
TEMP=/tmp/answer$$

DLG=/usr/bin/dialog


$DLG --timeout 5 --msgbox "Welcome to Precinct Ballot Counter! \n\nOSET Foundation\nCopyright 2017" 10 40
$DLG --timeout 5 --msgbox "This is where the PBC's guts go..." 10 40
