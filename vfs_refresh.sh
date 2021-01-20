#!/bin/bash
rclone_refresh ()
{
#set recurse = false for selected folder
echo "begining vfs/refresh recursive=false of ${2}"
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
#TV 
rclone_refresh "5577" "zd-tv2/tv/20s" 
rclone_refresh "5577" "zd-tv2/tv/10s"
rclone_refresh "5577" "zd-tv1/tv/00s"
rclone_refresh "5577" "zd-tv1/tv/90s"
rclone_refresh "5577" "zd-tv1/tv/80s"
rclone_refresh "5577" "zd-tv1/tv/70s"

#4K TV
#rclone_refresh "5577" "zd-tv3/tv/4k" 