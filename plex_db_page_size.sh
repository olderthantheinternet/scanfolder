#!/bin/bash
plexdb="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plexdocker="plex"

needed=32768;
cmd="pragma page_size"
#IFS=$'\n'
fqry=(`sqlite3 "$plexdb" "$cmd"`)
#unset IFS
if [ "$fqry" -eq "$needed" ]; then echo "page_size is already set to ${fqry}" exit; fi

#docker stop "${plexdocker}"
plexdb=$(dirname "$plexdb")
echo "$plexdb"

echo "page size needs changing as it's currently set to ${fqry}"


cd "${plexdb}"
exit;
cp com.plexapp.plugins.library.db com.plexapp.plugins.library.db.original
sqlite3 com.plexapp.plugins.library.db "DROP index 'index_title_sort_naturalsort'"
sqlite3 com.plexapp.plugins.library.db "DELETE from schema_migrations where version='20180501000000'"
sqlite3 com.plexapp.plugins.library.db .dump > dump.sql
rm com.plexapp.plugins.library.db
sqlite3 com.plexapp.plugins.library.db
#will go into the sqlite console
pragma page_size = 32768;
vacuum;
# ctrl+d to quit console
# check page_size changed
sqlite3 com.plexapp.plugins.library.db "pragma page_size;"
sqlite3 com.plexapp.plugins.library.db < dump.sql
docker start "${plexdocker}"
