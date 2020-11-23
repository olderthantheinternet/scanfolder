# scanfolder

this will compare the contents of a folder against your plex database and add any missing content to AUTOSCAN

```
# cd /mnt/unionfs
# bash -x /path/scanfolder/scanfolder.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -d 2 -h 3 -p usernamepassword -o plex -z '/path to plex db/' -w 30
# -d, -h, and -p are optional
# and when using -d or -h, you only use one - not both
# -d = days ago and -h = hours ago
# -w = number of seconds to wait between sends to autoscan, defauls to 10 if value is not set
while getopts s:c:t:u:d:h:p:o:z:w: option; do 
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
        w) WAIT=${OPTARG};;
     esac
done
```
SOURCE_FOLDER = the folder you want scanfolder to look at "/tv/10s" or "/movies/10s" 

CONTAINER_FOLDER = the base folder of your union "/mnt/unionfs/"

TRIGGER = this will be either "tv" or "movie"

URL = this is your autoscan URL "http://autoscan:3030"

DAYSAGO = the script will only look at data that is X number of days old

HOURSAGO = the script will only look at data that is X hours old

USERPASS = for the autoscan URL (if used) in the form of username:password

DOCKERNAME = the container name of your plex

PLEXDB = complete path to your plex DB, note, if using Cloudbox you can skip defining it

WAIT = the number of seconds to wait between sending to autoscan

the script needs to be started in the base folder of your media, like "/mnt/unionfs"
but, if you want it to scan content separate from the union, so it only see ZenDrive and not ZD_TDs
you can start the script from "/mnt/sharedrives/zd-storage/zd-tv/"  or "zd-movies"

So for TV it would look like:
```
seed@superplex:~$ cd /mnt/unionfs
seed@superplex:/mnt/unionfs$ bash -x /path/scanfolder/scanfolder.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -d 2 -p usernamepassword -o plex
```
or from the ZenDrive folder
```
seed@superplex:~$ cd /mnt/sharedrives/zd-storage/zd-tv2/
seed@superplex:/mnt/sharedrives/zd-storage/zd-tv2$ bash -x /path/scanfolder/scanfolder.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -h 3 -p usernamepassword -o plex
```

And for MOVIES it would look like:
```
seed@superplex:~$ cd /mnt/unionfs
seed@superplex:/mnt/unionfs$ bash -x /path/scanfolder/scanfolder.sh -s movies/10s -c /mnt/unionfs/ -t movie -u http://autoscan.TDL:3030 -d 2 -p usernamepassword -o plex
```
or from the ZenDrive folder
```
seed@superplex:~$ cd /mnt/sharedrives/zd-storage/zd-movies/
seed@superplex:/mnt/sharedrives/zd-storage/zd-movies2$ bash -x /path/scanfolder/scanfolder.sh -s movies/10s -c /mnt/unionfs/ -t movie -u http://autoscan.TDL:3030 -d 2 -p usernamepassword -o plex
```



#NOTE:

the script assumes the triggers in your config.yml are sonarr & radarr

and finally a shout out to "m1lkman" for coming up with the code for the process_autoscan funtion
https://discord.com/channels/381077432285003776/738466261473951804/769287309123387433
