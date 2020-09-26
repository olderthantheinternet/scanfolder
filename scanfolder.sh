#!/bin/bash
SOURCE_FOLDER=$1
SECTION=$2
CONTAINER_FOLDER=$3
INPUT="/opt/scripts/section-$SECTION-${SOURCE_FOLDER///}-folders.txt"
DOCKERNAME="plex"

get_folders () {

for f in "$SOURCE_FOLDER"/*; do
    if [ -d "${f}" ]; then
        f1=$(printf "%s" "$f" | sed 's|[\]||g')
        f2=$(printf "%s" "$f1" | sed "s/'/\"/g")
        
        exists=$( sqlite3 /opt/plex/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db "select count(*) from media_parts where file like '%$f2%'" )
        if (( exists > 0 )); then
             echo "It exists!"
             linecount="$( find ./"$f2" -type f \( -iname \*.mkv -o -iname \*.mpeg -o -iname \*.ts -o -iname \*.avi -o -iname \*.mp4 -o -iname \*.m4v -o -iname \*.asf -o -iname \*.mov -o -iname \*.mpegts -o -iname \*.vob -o -iname \*.divx -o -iname \*.wmv \) | wc -l )"
             if test $linecount -eq $exists; then
                echo "episode count the same"
             else
                echo "update show"
                h=$(printf %q "$f1")
                echo $h >> $INPUT
             fi 
        else
             echo "new show"
             h=$(printf %q "$f1")
             echo $h >> $INPUT
        fi  
    fi
done

process_folders () {

line=$(head -n 1 $INPUT)

if [ -z "$line" ]
then
      echo "\$line is empty - deleting control file"
        rm -rf $INPUT
      exit 7
else
      echo "\$line is NOT empty - processng control file"
      process_docker "$line"
fi


}

process_docker () {

        g='export LD_LIBRARY_PATH=/usr/lib/plexmediaserver;/usr/lib/plexmediaserver/Plex\ Media\ Scanner --scan --refresh --section '$SECTION
        gg='--directory '$CONTAINER_FOLDER$1
        g="${g} ${gg}"
        docker exec -u plex -i $DOCKERNAME bash -c "$g"
        if [[ $? -ne 0 ]]; then
                echo $1 >> /tmp/failedscans.txt
                sed --in-place '1d' $INPUT
        else
                sed --in-place '1d' $INPUT
                sleep 35
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
