#!/bin/bash
# /path/scanfolder/scanfolder.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -p usernamepassword -o plex -z '/path to plex db/' -w 10 -r zendrive -a zd-tv2
#-w = second to wait between sends to autoscan
#-r = RCLONE mount, like zendrive or zd_storage
#-a = the folder name at the base of the mount: zd-movies,zd-tv1,zd-tv2,zd-tv3
while getopts s:c:t:u:p:o:z:w:r:a: option; do 
    case "${option}" in
        s) SOURCE_FOLDER=${OPTARG};;
        c) CONTAINER_FOLDER=${OPTARG};;
        t) TRIGGER=${OPTARG};;
        u) URL=${OPTARG};;
        p) USERPASS=${OPTARG};;
        o) DOCKERNAME=${OPTARG};;
        z) PLEXDB=${OPTARG};;
        w) WAIT=${OPTARG};;
        r) RCLONEMOUNT=${OPTARG};;
        a) ZDTD=${OPTARG};;
               
     esac
done

get_files ()
{
  case $TRIGGER in
          movie)
                  depth=2
                  ;;
          tv|television|series)
                  depth=3
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
  IFS=$'\n' 
  filelist=($(rclone lsf --files-only --absolute --max-depth "$depth" --format pt --separator "|" "$RCLONEMOUNT:$ZDTD/$SOURCE_FOLDER"))
  unset IFS
  file_list=()
  for i in "${filelist[@]}"
  do
     file_list+=("${CONTAINER_FOLDER}${SOURCE_FOLDER}${i}")
  done
}

get_db_items ()
{ 
         cmd="select p.file,p.created_at from media_items m inner join media_parts p on m.id=p.media_item_id WHERE p.file LIKE '%$SOURCE_FOLDER/%'"
         if [ ! -z "$PLEXDB" ]
         then
             plex="${PLEXDB}com.plexapp.plugins.library.db"
         else
             plex="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
         fi
         db_list=()
         IFS=$'\n'
         fqry=(`sqlite3 "$plex" "$cmd"`)
         unset IFS
         for f in "${fqry[@]}"; do
           db_list+=("${f}")
         done
}

process_autoscan () {
        case $TRIGGER in
          movie)
                  arrType="radarr"
                  #folderPath="$(dirname "${1}")"
                  folderPath="$1"
                  relativePath=$(basename "$folderPath")
                  jsonData='{"eventType": "Download", "movie": {"folderPath": "'"$folderPath"/'"}, "movieFile": {"relativePath": "'"$relativePath"/'"}}'
                  ;;
          tv|television|series)
                  arrType="sonarr"
                  folderPath="$1"
                  relativePath=$(basename "$folderPath")
                  jsonData='{"eventType": "Download","episodeFile": {"relativePath": "'"$relativePath"'"},"series": {"path": "'"$folderPath"/'"}}'
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
        else
          if [ -z "$WAIT" ]
          then
              sleep 10
          else
              sleep "$WAIT"
          fi
        fi
}

autoscan_check ()
{
         sql="SELECT EXISTS(SELECT 1 scan WHERE u_tag=folder like '"${1}"' LIMIT 1)"
         scan="/opt/autoscan/autoscan.db"
         check=0
         if [ "`sqlite3 "$scan" "$sql"`" != "0" ]
         then
            check=1
         fi
}

get_files
get_db_items
IFS=$'\n'
mapfile -t missing_files < <( comm -13 <(printf '%s\n' "${db_list[@]}" | LC_ALL=C sort) <(printf '%s\n' "${file_list[@]}" | LC_ALL=C sort) )
unset IFS
declare -a farray
for i in "${missing_files[@]}"; 
do
  f=("$(cut -d '|' -f1 <<< "$i")");
  f=${f//[$'\t\r\n']}
  farray+=("$(dirname "${f}")")
done
IFS=$'\n'
readarray -t uniq < <(printf '%s\n' "${farray[@]}" | sort -u)
unset IFS
c=1
for i2 in "${uniq[@]}"; 
do 
  g=${i2//[$'\t\r\n']}
  if [ "${g}" != "${CONTAINER_FOLDER}${SOURCE_FOLDER}" ]; then
     autoscan_check "${g}";
     if[ $check = 0 ]; then
        process_autoscan "${g}";
     fi
  fi
  c=$[$c +1]
done
echo "${c} files processed"
