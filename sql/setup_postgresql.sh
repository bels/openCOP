#!/usr/bin/env bash

DATABASE=$1
sql=postgresql.sql
PATH=$PATH:/usr/bin:/bin:/usr/local/bin
echo "This script makes some assumptions.  Let me get them out of the way right now"
echo "1. You are running this as a user that has superuser privileges in the database"
echo "2. That you have createdb installed and available in that user's PATH"
echo "3. That psql is available in that user's PATH"
echo "4. You are running this script from the same directory as postgresql.sql"

echo "With that said, lets begin"
echo "Creating database"

function missing {
	echo missing $@
	exit
}
while read -d' ' program ; do which $program >/dev/null || missing $program ; done <<< "$(echo psql dropdb createdb createlang)"

dropdb $DATABASE 2>/dev/null
createdb $DATABASE
createlang plpgsql $DATABASE

# note: with test (aka [) != is for string comparison only (man test) and -ne 
# is for integer comparison. You wont exactly get what you expect if you use 
# != with numbers. Yes, this is exactly backwards from perl != and ne
if [ $? -ne 0 ] ; then
	echo "Couldn't create the database. Check my assumptions that I listed and then re-run this script."
	exit 1
fi

if [ -f $sql ] ; then
	echo "Importing database schema\n"
	psql $DATABASE < $sql
	if [ $? -ne 0 ] ; then
		echo "Couldn't import the database. Check my assumptions that I listed and then re-run this script."
		exit 1
	fi
	echo "All Done. Enjoy!\n"
else
	echo $sql not found
fi
