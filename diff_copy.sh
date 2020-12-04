#!/bin/bash
# /path/scanfolder/diff_copy.sh -a 5 -b /mnt/unionfs/mymovies/ -c myrclone:mypath -d zdinbound:some_path -e (tv or movie) -p '/path to plex db/'
while getopts a:b:c:d:e:p: option; do 
    case "${option}" in
        a) SECID=${OPTARG};;
        b) YOURMEDIA=${OPTARG};;
        c) YOURRCLONE=${OPTARG};;
        d) ZDRCLONE=${OPTARG};; 
        e) MEDIATYPE=${OPTARG};; 
        p) PLEXDB=${OPTARG};; 
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

process_diff ()
{
        if [ ! -z "$PLEXDB" ]
         then
             plex="${PLEXDB}com.plexapp.plugins.library.db"
         else
             plex="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
        fi
        unset cmd
        case $MEDIATYPE in
          movie)
cmd="SELECT \
p.file \
FROM metadata_items md \
inner join media_items m ON m.metadata_item_id=md.id \
inner join media_parts p on m.id=p.media_item_id \
WHERE md.library_section_id = '$SECID' and md.guid NOT IN \
( \
SELECT \
md2.guid \
FROM metadata_items md2 \
inner join media_items m2 ON m2.metadata_item_id=md2.id \
inner join media_parts p2 on m2.id=p2.media_item_id \
WHERE md2.library_section_id = '$SECID' AND p2.file NOT LIKE '%$YOURMEDIA%' \
)"
                  echo "${cmd}"
                  ;;
          tv|television|series)
                  cmd=""
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
        db_list=()
        IFS=$'\n'
        fqry=(`sqlite3 "$plex" "$cmd"`)
        unset IFS
        for f in "${fqry[@]}"; do
          f=${f//[$'\t\r\n']}
          db_list+=(basename("$(dirname "${f}")"))
        done
}

process_diff
printf '%s\n' "${db_list[@]}"
exit;
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
  if [ ! -z "$g" ]; then
     if [ "${g}" != "${CONTAINER_FOLDER}${SOURCE_FOLDER}" ]; then
        autoscan_check
        if [ "$check" -eq "0" ]; then
           process_autoscan "${g}";
        fi
     fi
     c=$[$c +1]
  fi
done
echo "${c} files processed"
