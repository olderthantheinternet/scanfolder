# scanfolder

```
#bin/bash
SOURCE_FOLDER=$1
CONTAINER_FOLDER=$2
TRIGGER=$3
URL=$4
INPUT="/opt/scanfolders/section-$TRIGGER-${SOURCE_FOLDER///}-folders.txt"
DOCKERNAME="plex"
```
SOURCE_FOLDER = the folder you want scanfolder to look at "/tv/10s" or /movies/10s"the base folder of your union "/mnt/unionfs/"
CONTAINER_FOLDER = the base folder of your union "/mnt/unionfs/"
TRIGGER = this will be either "tv" or "movie"
URL = this is your autscan URL "http://autoscan:3030"

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
