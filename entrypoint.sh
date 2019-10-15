#!/bin/sh

# "to avoid continuing when errors or undefined variables are present"
set -eu

echo "Starting FTP Deploy"

WDEFAULT_LOCAL_DIR=${LOCAL_DIR:-"."}
WDEFAULT_REMOTE_DIR=${REMOTE_DIR:-"."}
WDEFAULT_ARGS=${ARGS:-""}
WDEFAULT_METHOD=${METHOD:-"ftp"}
WDEFAULT_SETTIMESTAMPS=${DIFFS_ONLY:-true}

if $WDEFAULT_SETTIMESTAMPS; then
	start=`date +%s`
	IFS=$'\n'
	list_of_files=($(git ls-files | sort))
	unset IFS
	
	echo "Using Local git log to restore last_modified dates on files"

	echo "|----------------------------------------------------|-------------------------------|"
	printf "| %-50.50s | %10s |%b\n" "FileName" "New Timestamp                "
	echo "|----------------------------------------------------|-------------------------------|"

	for file in "${list_of_files[@]}"; do
	  file_name=$(echo $file)

	  ## When you collect the timestamps:
	  TIMEPRETTY=$(date -r "$file_name")
	  TIME=$(date -r "$file_name" -Ins)

	  printf "| %-50.50s | %10s |%b\n" "$file_name" "$TIMEPRETTY"
	  
	  ## When you want to recover back the timestamps:
	  touch -m -d $TIME "$file_name"
	done
	echo "|----------------------------------------------------|-------------------------------|"
	end=`date +%s`
	runtime=$((end-start))
	echo "Updating last_modified dates took $runtime seconds"
fi;

if [ $WDEFAULT_METHOD = "sftp" ]; then
  WDEFAULT_PORT=${PORT:-"22"}
  echo "Establishing SFTP connection..."
  sshpass -p $FTP_PASSWORD sftp -o StrictHostKeyChecking=no -P $WDEFAULT_PORT $FTP_USERNAME@$FTP_SERVER
  echo "Connection established"
else
  WDEFAULT_PORT=${PORT:-"21"}
fi;

echo "Using $WDEFAULT_METHOD to connect to port $WDEFAULT_PORT"

echo "Uploading files..."
lftp $WDEFAULT_METHOD://$FTP_SERVER:$WDEFAULT_PORT -u $FTP_USERNAME,$FTP_PASSWORD -e "set ftp:ssl-allow no; mirror $WDEFAULT_ARGS -R $WDEFAULT_LOCAL_DIR $WDEFAULT_REMOTE_DIR; quit"

echo "FTP Deploy Complete"
exit 0
