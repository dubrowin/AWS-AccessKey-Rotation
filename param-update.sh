#!/bin/bash

#########################
## Update locally stored
## AWS Access Keys
## via cron
##
## By: Shlomo Dubrowin
## Date: Aug 5, 2024
#########################

#########################
## Variables
#########################
# PARAMS is a space list of Parameters to test for
PARAMS="param-test backup-test"
PARAMS="param-test"
# PARAMREGION is if the Parameter Store is not in the default region
PARAMREGION="us-east-1"
# UPDATEBUCKET is the bucket used to collect the updates to identify which systems have updated their keys
UPDATEBUCKET="shlomod-976921666931-key-update"
# Profile if you are using an AWS CLI Profile in your configuration
PROFILE=""

## Do not update below here
TMP1="/tmp/$( basename "$0" ).1.tmp"
TMP2="/tmp/$( basename "$0" ).$HOSTNAME.tmp"
echo -e "\c" > $TMP2
DEBUG="Y"
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
TAG="$( basename "$0" )"

#########################
## Functions
#########################
function Debug {        
	if [ "$DEBUG" == "Y" ]; then                
		if [ ! -z "$CRON" ]; then                        
			# Cron, output only to log                        
			# #echo -e "$( date +"%b %d %H:%M:%S" ) $1" >> $LOG                        
			logger -t $TAG "$$ running $SECONDS secs: $1"                
		else                        
			# Not Cron, output to CLI and log                        
			logger -t $TAG "$$ running $SECONDS secs: $1"                        
			echo -e "$( date +"%b %d %H:%M:%S" ) $$ running $SECOINDS secs: $1"                
		fi        
	fi
}

function Error {
	Debug "Error Occured, stopping"
	exit 1
}

#########################
## Main Code
#########################

if [ ! -z $PROFILE ]; then
	PROFILE="--profile $PROFILE"
fi
Debug "Using a profile setting of: $PROFILE"

for PARAMNAME in $PARAMS; do
	Debug "Processing $PARAMNAME"
	## Get the Param Data
	#PARAMS=`aws ssm get-parameter --name $PARAMNAME --region $PARAMREGION | grep Value | cut -d \" -f 4`
	aws ssm get-parameter --name $PARAMNAME --region $PARAMREGION | grep Value | cut -d \" -f 4 | awk '{gsub(/\\n/,"\n")}1' | grep -v "^$" > $TMP1 || Error
	#echo "PARAMS $PARAMS"
	#cat $TMP1

	## Find Latest Key
	NEWKEY=`cat $TMP1 | grep NEW -A 1 | grep -v NEW | cut -d = -f 2 | sed 's/^[ \t]*//'`
	#echo ${PARAMS} | tr '\\n' '\n' | grep -v "^$" | grep NEW -A 1 | cut -d = -f 2 | awk -F  '\' '{print $1}' | sed 's/^[ \t]*//'`
	Debug "NEWKEY $NEWKEY"

	## Is the Latest Key being used?
	NEWKEYSTAT=`find ~/.aws/ \( -name "config" -o -name "credentials" \) -exec grep -c ${NEWKEY} {} \; | paste -sd+ - | bc`
	Debug "NEWKEYSTAT $NEWKEYSTAT"

	if [ "$NEWKEYSTAT" != "0" ]; then
		Debug "New Key is being used, nothing to do here"
	else
		Debug "New Key is NOT being used, need to implement it"

		# Determine which file the Old Key is being used
		OLDKEY=`cat $TMP1 | grep OLD -A 1 | grep -v OLD | cut -d = -f 2 | sed 's/^[ \t]*//'`
		Debug "OLDKEY $OLDKEY"
	
		FILEUPDATE=`find ~/.aws/ \( -name "config" -o -name "credentials" \) -exec grep -H $OLDKEY {} \; | grep -v  :0 | cut -d : -f 1`
		#FILEUPDATE=`find ~/.aws/ \( -name "config" -o -name "credentials" \) -exec grep -cH $OLDKEY {} \; | grep -v :0 | cut -d : -f 1`
		
		# Collect New and Old Secrets
		NEWSECRET=`grep $NEWKEY -A 1 $TMP1 | grep -v $NEWKEY | cut -d = -f 2 | sed 's/^[ \t]*//'`
		OLDSECRET=`grep $OLDKEY -A 1 $TMP1 | grep -v $OLDKEY | cut -d = -f 2 | sed 's/^[ \t]*//'`	
		#Debug "NEWSECRET $NEWSECRET OLDSECRET $OLDSECRET"
	
		COUNT="0"
	
		# Update the Old Key and Secret using the Param New Key and Secret
		for FILE in $FILEUPDATE; do
			Debug "Update: $FILE"
			let "COUNT = $COUNT + 1"

			# Do the Update of Access Key and Secret Key
			#Debug "sed -i \"s/${OLDKEY}/${NEWKEY}/g\" $FILE || Error"
			sed -i "s/${OLDKEY}/${NEWKEY}/g" $FILE || Error
			#Debug "sed -i \"s:${OLDSECRET}:${NEWSECRET}:g\" $FILE || Error"
			sed -i "s:${OLDSECRET}:${NEWSECRET}:g" $FILE || Error

			# Update Notification
			Debug "Param $PARAMNAME updated to $NEWKEY in $FILE written to $TMP2" 
			echo "Param $PARAMNAME updated to $NEWKEY in $FILE" >> $TMP2
		done

		if [ "$COUNT" == "0" ]; then
			# No update was made
			Debug "Error: no file found to update"
		fi

	fi
done

TMP2STAT=`cat $TMP2 | wc -l`
if [ "$TMP2STAT" != "0" ]; then
	Debug "TMP2 ($TMP2) was used ($TMP2STAT), sending to $UPDATEBUCKET"
	aws s3 cp $TMP2 s3://${UPDATEBUCKET} || Error
fi

Debug "removing $TMP1 $TMP2"
rm $TMP1 $TMP2
