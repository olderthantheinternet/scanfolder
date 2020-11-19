#!/bin/bash
SOURCE_FOLDER=$1
CONTAINER_FOLDER=$2
TRIGGER=$3
URL=$4
USERPASS=$5
INPUT="/opt/scanfolder/section-$TRIGGER-${SOURCE_FOLDER///}-folders.txt"
DOCKERNAME="plex"

get_folders () {

for f in "$SOURCE_FOLDER"/*; do
    if [ -d "${f}" ]; then
        f1=$(printf "%s" "$f" | sed 's|[\]||g')
	f2=$(printf "%b" "$f1" | sed "s/'/\"/g")
        exists=$( sqlite3 /opt/plex/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db "select count(*) from media_parts where file like '%$f2%'" )
        if (( exists > 0 )); then
             echo "It exists!"
             linecount="$( find ./"$f2" -type f \( -iname \*.mkv -o -iname \*.mpeg -o -iname \*.m2ts -o -iname \*.ts -o -iname \*.avi -o -iname \*.mp4 -o -iname \*.m4v -o -iname \*.asf -o -iname \*.mov -o -iname \*.mpegts -o -iname \*.vob -o -iname \*.divx -o -iname \*.wmv \) | wc -l )"
	if test $linecount -eq $exists; then
                echo "item count the same"
             else
                echo "update media"
                h=$(printf %q "$f1")
                echo $h >> $INPUT
             fi 
        else
             echo "new media"
             h=$(printf %q "$f1")
             echo $h >> $INPUT
        fi  
    fi
done
}

process_folders () {

line=$(head -n 1 $INPUT)

if [ -z "$line" ]
then
      echo "\$line is empty - deleting control file"
        rm -rf $INPUT
      exit 7
else
      echo "\$line is NOT empty - processng control file"
      process_autoscan "$line"
fi

}

process_autoscan () {

	case $TRIGGER in
	  movie)
		  arrType="radarr"
		  foldera=$(printf "$CONTAINER_FOLDER$1" | sed 's/[\]//g')
		  folderPath=$(printf "$foldera" | sed "s/['\']/'/g")
		  relativePath=$(basename "$folderPath")
		  jsonData='{"eventType": "Download", "movie": {"folderPath": "'"$folderPath"'"}, "movieFile": {"relativePath": "'"$relativePath"'"}}'
		  ;;
	  tv|television|series)
		  arrType="sonarr"
		  foldera=$(printf "$CONTAINER_FOLDER$1" | sed 's/[\]//g')
		  folderPath=$(printf "$foldera" | sed "s/['\']/'/g")
		  relativePath="season 1"
		  jsonData='{"eventType": "Download","episodeFile": {"relativePath": "'"$relativePath"'"},"series": {"path": "'"$folderPath"'"}}'
		  ;;
	  '')
		  echo "Media type parameter is empty"
		  exit;
		  ;;
	  *)
		  echo "Media type specified unknown"
		  exit;
		  ;;
	esac
	
	if [ -n "${USERPASS+set}" ]; then
   		curl -d "$jsonData" -H "Content-Type: application/json" $URL/triggers/$arrType -u $USERPASS > /dev/null
	else
   		curl -d "$jsonData" -H "Content-Type: application/json" $URL/triggers/$arrType > /dev/null
	fi
	
	if [ $? -ne 0 ]; then echo "Unable to reach autoscan ERROR: $?";fi
		echo "$1 added to your autoscan queue!"
	if [[ $? -ne 0 ]]; then
					echo $1 >> /tmp/failedscans.txt
					sed --in-place '1d' $INPUT
	else
			sed --in-place '1d' $INPUT
			sleep 2
	fi
	process_folders
}

if [ -f "$INPUT" ]; then
    process_folders
else
    get_folders
    process_folders
fi

}
