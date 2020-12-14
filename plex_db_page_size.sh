#!/bin/bash
plexdb="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plexdocker="plex"

check ()
{
   $needed=32768;
   cmd="pragma page_size"
   IFS=$'\n'
   fqry=(`sqlite3 "$plex" "$cmd"`)
   unset IFS
   if [ "$fqry" -eq "$needed" ]; then
      echo "page_size is already set to ${fqry}"
      exit;
   fi
}

check

echo "page size needs changing"
exit;

docker stop "${plexdocker}"

cd "${plexdb}"
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
