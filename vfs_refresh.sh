#!/bin/bash
#
#
function usage {
  echo ""
  echo "Usage: bash vfs_refresh.sh \"PORT\" \"AREA TO REFRESH\" "
  echo ""
  echo "Examples:"
  echo "    bash vfs_refresh.sh \"5590\" \"TV\" "
  echo "    bash vfs_refresh.sh \"5590\" \"TV4K\" "
  echo "    bash vfs_refresh.sh \"5590\" \"MOVIES\" "
  echo "    bash vfs_refresh.sh \"5590\" \"MOVIES4K\" "
  exit 1
}
if [ -z "$1" ] && [ -z "$2" ]
  echo "please provide a port number and Media type"
  usage
fi

if [ -z "$1" ]
  echo "please provide a port number"
  usage
fi

if [ -z "$2" ]
  echo "please provide an area to refresh"
  usage
fi

rclone_refresh ()
{
#set recurse = false for selected folder
echo "beginning vfs/refresh recursive=false of ${2}"
VAR=$(/usr/bin/rclone rc vfs/refresh --rc-addr=localhost:"$1" _async=true recursive=false dir="$2" | grep "jobid")
JID=${VAR#*:}
JID=$(echo -e "${JID}" | tr -d '[:space:]')
VAR2=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "success")
value=${VAR2#*:}
value=$(echo -e "${value}" | tr -d '[:space:]')
while [ "$value" != "true" ]; do
  VAR2=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "success")
  value=${VAR2#*:}
  value=$(echo -e "${value}" | tr -d '[:space:]')
  sleep 1
done
# if recursive false retuns OK, then continue with recursive true
CHECK=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "$2")
CHECK=${CHECK:(-4)}
CHECK=${CHECK//\"/}
if [ "$CHECK" = "OK" ]; then
   echo "vfs/refresh recursive=false of ${2} completed"
   if [ "$USEVFS" != "1" ]; then
    echo "No VFS Cache so NO recursive=true"
   else
       echo "beginning vfs/refresh recursive=true of ${2}"
       VAR=$(/usr/bin/rclone rc vfs/refresh --rc-addr=localhost:"$1" _async=true recursive=true dir="$2" | grep "jobid")
       JID=${VAR#*:}
       JID=$(echo -e "${JID}" | tr -d '[:space:]')
       VAR2=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "success")
       value=${VAR2#*:}
       value=$(echo -e "${value}" | tr -d '[:space:]')
       while [ "$value" != "true" ]; do
         VAR2=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "success")
         value=${VAR2#*:} 
         value=$(echo -e "${value}" | tr -d '[:space:]')
         sleep 1
       done
       CHECK=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "$2")
       CHECK=${CHECK:(-4)}
       CHECK=${CHECK//\"/}
       if [ "$CHECK" = "OK" ]; then
        echo "vfs/refresh recursive=true of ${2} completed"
       else
         echo "vfs/refresh recursive=true of ${2} failed, exiting script"
         exit
       fi
    fi
else
   echo "vfs/refresh recursive=false of ${2} failed, exiting script"
   exit
fi
}

USEVFS="1"
RCPORT="$1"
if [ "$2" = "TV" ]; then
    #TV 
    rclone_refresh "${1}" "zd-tv2/tv/20s" &
    rclone_refresh "${1}" "zd-tv2/tv/10s" &
    rclone_refresh "${1}" "zd-tv1/tv/00s" &
    rclone_refresh "${1}" "zd-tv1/tv/90s" &
    rclone_refresh "${1}" "zd-tv1/tv/80s" &
    rclone_refresh "${1}" "zd-tv1/tv/70s" &
fi

if [ "$2" = "TV4K" ]; then
    #4K TV
    rclone_refresh "${1}" "zd-tv3/tv/4k" &
fi

if [ "$2" = "MOVIES" ]; then
    USEVFS=""
    #Movies
    rclone_refresh "${1}" "zd-movies/movies/20s" &
    rclone_refresh "${1}" "zd-movies/movies/10s" &
    rclone_refresh "${1}" "zd-movies/movies/00s" &
    rclone_refresh "${1}" "zd-movies/movies/90s" &
    rclone_refresh "${1}" "zd-movies/movies/80s" &
    rclone_refresh "${1}" "zd-movies/movies/70s" &
fi

if [ "$2" = "MOVIES4K" ]; then
    #Movies 4K
    rclone_refresh "${1}" "zd-movies/movies/4k" &
    rclone_refresh "${1}" "zd-movies/movies/4k-dv" &
fi

wait
echo "all vfs/refresh commands have finished"