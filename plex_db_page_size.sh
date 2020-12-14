#!/bin/bash
plexdb="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plexdocker="plex"

N=(`sqlite3 "$plexdb" "pragma page_size"`)
if [ "$N" -eq "32768" ]; then 
  echo "page_size is already set to $N" 
  #exit; 
fi

#docker stop "${plexdocker}"
plexdb=$(dirname "$plexdb")
cd "$plexdb/";
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
