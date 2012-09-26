#!/bin/bash
# - title        : Uploading Cloud Files Objects
# - description  : This script will assist in Uploading a lot of files to Cloud Files
# - author       : Kevin Carter
# - date         : 2011-09-03
# - version      : 1.0    
# - usage        : bash massupload.sh
# - notes        : This is a Cloud Files upload script
# - bash_version : >= 3.2.48(1)-release

# This software has no warranty, it is provided “as is”. It is your responsibility 
# to validate the behavior of the routines and its accuracy using the code provided.  
# Consult the GNU General Public license for further details (see GNU General Public License).
# http://www.gnu.org/licenses/gpl.html

#### ========================================================= ####

TIME=$(which time)

trap CONTROL_C SIGINT

CONTROL_C(){
echo ''
echo "AAHAHAAHH! FIRE! CRASH AND BURN!"
echo "     You Pressed [ CTRL C ]     "
	QUIT
}

##  Exit  ##
QUIT(){
  echo -e "\nExiting\nCleaning Up my mess...\n"
  IFS=$0
exit $?
}

# RS Username 
if [ -z "$USERNAME" ];then 
  read -p "Enter your Username : " USERNAME
fi

# RS API Key 
if [ -z "$APIKEY" ];then 
  read -p "Enter your API Key : " APIKEY
fi

# Authentication v2.0 URL
if [ -z "$LOCAL" ];then
  read -p "Enter The Cloud Files Location, (us or uk) : " LOCAL
fi
if [ "$LOCAL" == "us" ];then
  AUTHURL='https://auth.api.rackspacecloud.com/v2.0'
elif [ "$LOCAL" == "uk" ];then
  AUTHURL='https://lon.auth.api.rackspacecloud.com/v2.0'
else 
  echo "You have to put in a Valid Location, which is \"us\" or \"uk\"."
  exit 1 
fi

# Normal or Snet Connection
if [ -z "$CONURL" ];then
  read -p "Enter Connection URL, (norm or snet) : " CONURL
fi
if [ "${CONURL}" == "norm" ]; then
echo -e "\nUsing Normal Network"
  elif [ "${CONURL}" == "snet" ]; then
  echo -e "\nUsing Service Network"
else
  echo "You did not specify one of the TWO Connection Types (norm or snet)"
  exit 1
fi

# DC Selection if needed
if [ -z "$DC" ];then
    read -p "Enter The DC, (dfw or ord) : " DC
fi
  if [ "${DC}" == "dfw" ]; then
    echo "Using DFW"
      elif [ "${DC}" == "ord" ]; then
      echo "Using ORD"
	elif [ "${DC}" == "lon" ]; then
	echo "Using LON"
	  else
	  echo "You did not specify one of the TWO Datacenters (dfw or ord)"
	  exit 1
  fi

# Name the Container
if [ -z "$CONTAINER" ];then
  read -p "Enter Container Name : " CONTAINER
fi

# Creating a service list catalog
SERVICECAT=$( curl -s -X POST ${AUTHURL}/tokens -d " { \"auth\":{ \"RAX-KSKEY:apiKeyCredentials\":{ \"username\":\"${USERNAME}\", \"apiKey\":\"${APIKEY}\" }}}" -H "Content-type: application/json" | python -m json.tool )

# Setting the Storage URL
if [ "${CONURL}" == "norm" ]; then
STORAGEURL=$(echo $SERVICECAT | python -m json.tool | awk -F '"' '/storage101/ {print $4}' | grep -v snet | grep ${DC})
  elif [ "${CONURL}" == "snet" ]; then
  STORAGEURL=$(echo $SERVICECAT | python -m json.tool | awk -F '"' '/storage101/ {print $4}' | grep snet | grep ${DC})
    else 
    echo -e "\nSomething went wrong, exiting.\n"
    exit 1
fi

echo "Found Storage URL : $STORAGEURL"

# Setting the Token
TOKEN=$(echo $SERVICECAT | python -m json.tool | grep -A3 -i token | awk -F '"' '/id/ {print $4}')

# Checking for Container Error
CHECKCONTAINER=$( curl -s -X GET -D - -H "X-Storage-Token: ${TOKEN}" ${STORAGEURL}/${CONTAINER} | grep -i 'http\/[0-9]\.[0-9] 4[0-9][0-9]' )
if [ "$CHECKCONTAINER" ];then
  echo -e "\nThe Container that you asked for did not exist.\n"
  echo -e "Would you like to create it?\n"
  read -p "Enter [ yes ] or [ no ] : " CREATECONTAINER
    if [ "$CREATECONTAINER" == "yes" ] || [ "$CREATECONTAINER" == "Yes" ] || [ "$CREATECONTAINER" == "YES" ];then 
      curl -D - -X PUT -H "X-Auth-Token: $TOKEN" ${STORAGEURL}/${CONTAINER}
	else
	  echo -e "\nI am not creating the container, so I am quiting."
	  echo -e "You have to specify the correct container" 
	  echo -e "and or create it to upload files to it."
	  exit 1
    fi
fi

# Finding the files that you want to upload
read -p "Enter the full path to the directory that you want to upload : " FULLPATH
if [ ! -d $FULLPATH ];then
    echo "Directory not found so I quit."
    QUIT
fi 

cd $FULLPATH;
HUGEFILELIST=$(find -type f | sed -e 's/^.\///g')

# Building the Object Count 
OBJECTAMOUNT=$( echo -e "$HUGEFILELIST" | wc -l )

echo -e "\nThere are \"$OBJECTAMOUNT\" files in this directory, \"$FULLPATH\""
echo -e "\nYou are about to upload \"$OBJECTAMOUNT\" files, to container \"$CONTAINER\"\n".
read -p "Press [ Enter ] to continue or [ CTRL-C ] to quit"

echo -e "\nStorage Token : $TOKEN"
echo -e "${STORAGEURL}/${CONTAINER}\n"
echo -e "\nStarting the upload...\n"


O=$IFS
IFS=$(echo -en "\n\b")

for UPLOADER in $(echo -e "${HUGEFILELIST}"); do curl -s -X PUT -T "${UPLOADER}" -H "X-Auth-Token: $TOKEN" ${STORAGEURL}/${CONTAINER}/$(echo -e "$UPLOADER" | sed -e 's/\\ /\%20/g' -e 's/\//\%2F/g') | grep -i 'http\/[0-9]\.[0-9] 4[0-9][0-9]';done

IFS=$0

# Check if all of the files were uploaded correctly
CHECKCONTAINER=$( curl -s -X GET -D - -H "X-Storage-Token: ${TOKEN}" ${STORAGEURL}/${CONTAINER} | grep -i 'http\/[0-9]\.[0-9] 4[0-9][0-9]' )
CONTAINEROBJECTAMOUNT=$( curl -s -X HEAD -D - -H "X-Storage-Token: ${TOKEN}" ${STORAGEURL}/${CONTAINER} | col -b | grep "X-Container-Object-Count:" | awk '{print $2}' )

if [ ! "$CHECKCONTAINER" ];then
    echo -e "Here are the stats on the container that you uploaded too.\n"
    curl -s -X HEAD -D - -H "X-Storage-Token: ${TOKEN}" ${STORAGEURL}/${CONTAINER}
fi

echo "All done..."

QUIT