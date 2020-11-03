# scanfolder

this will compare the contents of a folder against your plex database and add any missing content to AUTOSCAN

```
#bin/bash
SOURCE_FOLDER=$1
CONTAINER_FOLDER=$2
TRIGGER=$3
URL=$4
USERPASS=$5
INPUT="/opt/scanfolder/section-$TRIGGER-${SOURCE_FOLDER///}-folders.txt"
DOCKERNAME="plex"
```
SOURCE_FOLDER = the folder you want scanfolder to look at "/tv/10s" or "/movies/10s" 

CONTAINER_FOLDER = the base folder of your union "/mnt/unionfs/"

TRIGGER = this will be either "tv" or "movie"

URL = this is your autoscan URL "http://autoscan:3030"

USERPASS = for the autoscan URL (if used) in the form of username:password

the script needs to be started in the base folder of your media, like "/mnt/unionfs"
but, if you want it to scan content separate from the union, so it only see ZenDrive and not ZD_TDs
you can start the script from "/mnt/sharedrives/zd-storage/zd-tv/"  or "zd-movies"

So for TV it would look like:
```
seed@superplex:~$ cd /mnt/unionfs
seed@superplex:/mnt/unionfs$ bash -x /opt/scanfolder/scanfolder.sh tv/20s /mnt/unionfs/ tv http://autoscan:3030
```
or from the ZenDrive folder
```
seed@superplex:~$ cd /mnt/sharedrives/zd-storage/zd-tv2/
seed@superplex:/mnt/sharedrives/zd-storage/zd-tv2$ bash -x /opt/scanfolder/scanfolder.sh tv/20s /mnt/unionfs/ tv http://autoscan:3030
```

And for MOVIES it would look like:
```
seed@superplex:~$ cd /mnt/unionfs
seed@superplex:/mnt/unionfs$ bash -x /opt/scanfolder/scanfolder.sh movies/20s /mnt/unionfs/ movie http://autoscan:3030
```
or from the ZenDrive folder
```
seed@superplex:~$ cd /mnt/sharedrives/zd-storage/zd-movies/
seed@superplex:/mnt/sharedrives/zd-storage/zd-movies2$ bash -x /opt/scanfolder/scanfolder.sh movies/20s /mnt/unionfs/ movie http://autoscan:3030
```



#NOTE:

the script assumes the triggers in your config.yml are sonarr & radarr

and finally a shout out to "m1lkman" for coming up with the code for the process_autoscan funtion
https://discord.com/channels/381077432285003776/738466261473951804/769287309123387433
