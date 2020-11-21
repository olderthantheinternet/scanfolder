#!/bin/bash
# cd /mnt/unionfs
# bash -x /path/scanfolder/scanfolder.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -d 2 -h 3 -p usernamepassword -o plex -z '/path to plex db/'
# -d, -h, and -p are optional
# and when using -d or -h, you only use one - not both
# -d = days ago and -h = hours ago
while getopts s:c:t:u:d:h:p:o: option; do 
    case "${option}" in
	s) SOURCE_FOLDER=${OPTARG};;
	c) CONTAINER_FOLDER=${OPTARG};;
	t) TRIGGER=${OPTARG};;
	u) URL=${OPTARG};;
	d) DAYSAGO=${OPTARG};;
	h) HOURSAGO=${OPTARG};;
	p) USERPASS=${OPTARG};;
	o) DOCKERNAME=${OPTARG};;
	z) PLEXDB=${OPTARG};;
     esac
done

mkdir -p "$HOME/scanfolder_data"
INPUT="$HOME/scanfolder_data/section-$TRIGGER-${SOURCE_FOLDER///}-folders.txt"


check_each_item ()
{
         fullfile=$CONTAINER_FOLDER$f2
         filename=$(basename -- "$fullfile")
         fullfile=$(printf "%s" "$fullfile" | sed 's|[\]||g')
         fullfile=$(printf "%s" "$fullfile" | sed "s/'/\"/g")
         cmd="select file from media_parts where file like '$fullfile%'"
	 if [ ! -z "$PLEXDB" ]
         then
	     plex=$(printf "%s" "$PLEXDB" | sed 's|[\]||g')
	     plex=$(printf "%s" "$plex" | sed "s/'/\"/g")
	     plex=$plex/com.plexapp.plugins.library.db
	 else
	     plex="/opt/plex/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db"
	 fi
	 IFS=$'\n'
         fqry=(`sqlite3 "$plex" "$cmd"`)
         for f in "${fqry[@]}"; do
           echo "$f"
	   if [ -f "$f" ]; then
	     echo "individual file names the same, no update"
	   else 
	     echo "update media"
             h=$(printf %q "$f1")
             echo $h >> $INPUT
	   fi
         done
}

get_folders () {
for f in "$SOURCE_FOLDER"/*; do
    if [ -d "${f}" ]; then
        f1=$(printf "%s" "$f" | sed 's|[\]||g')
        f2=$(printf "%s" "$f1" | sed "s/'/\"/g")
        fullfile=$CONTAINER_FOLDER$f
        fullfile=$(printf "%s" "$fullfile" | sed 's|[\]||g')
        fullfile=$(printf "%s" "$fullfile" | sed "s/'/\"/g")
        fullfile="$fullfile"
        if [ ! -z "$DAYSAGO" ]
        then
          DA="$DAYSAGO day ago"
          datecheck="$( find "$fullfile" -newermt "$DA" -type f | wc -l )"
        elif [ ! -z "$HOURSAGO" ]
	then
	  DA="$HOURSAGO hours ago"
          datecheck="$( find "$fullfile" -newermt "$DA" -type f | wc -l )"
	else
          datecheck=1
        fi
        if test $datecheck > 0; then
		SPCHECK='%'
		if [ ! -z "$PLEXDB" ]
		then
		     plex=$(printf "%s" "$PLEXDB" | sed 's|[\]||g')
		     plex=$(printf "%s" "$plex" | sed "s/'/\"/g")
		     plex=$plex/com.plexapp.plugins.library.db
		else
		     plex="/opt/plex/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db"
		fi
		if [[ "$f2" == *"$SPCHECK"* ]]; then
		  f3=$(printf "%s" "$f2" | sed 's/%/:%/g')
		  echo "theres a percent sign"
		  exists=$( sqlite3 "$plex" "select count(*) from media_parts where file like '%$f3%' ESCAPE ':'" )
		else
		  exists=$( sqlite3 "$plex" "select count(*) from media_parts where file like '%$f2%'" )
		fi
		if (( exists > 0 )); then
		     echo "It exists!"
		     linecount="$( find ./"$f2" -type f \( -iname \*.mkv -o -iname \*.mpeg -o -iname \*.m2ts -o -iname \*.ts -o -iname \*.avi -o -iname \*.mp4 -o -iname \*.m4v -o -iname \*.asf -o -iname \*.mov -o -iname \*.mpegts -o -iname \*.vob -o -iname \*.divx -o -iname \*.wmv \) | wc -l )"
		     if test $linecount -eq $exists; then
			echo "item count the same"
			#check all items to see if text matches
			check_each_item 
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
	
	
	if [ -z "$USERPASS" ] 
	then
   		curl -d "$jsonData" -H "Content-Type: application/json" $URL/triggers/$arrType > /dev/null
	else
   		curl -d "$jsonData" -H "Content-Type: application/json" $URL/triggers/$arrType -u $USERPASS > /dev/null
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
