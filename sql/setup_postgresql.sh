#!/usr/local/bin/bash

DATABASE="ccboehd"

echo "This script makes some assumptions.  Let me get them out of the way right now"
echo "1. You are running this as a user that has superuser privileges in the database"
echo "2. That you have createdb installed and available in that user's PATH"
echo "3. That psql is available in that user's PATH"
echo "4. You are running this script from the same directory as postgresql.sql"

echo "With that said, lets begin"
echo "Dropping database in case it is there.  Remember this is a fresh start."
dropdb $DATABASE
echo "Creating database"
createdb $DATABASE
createlang plpgsql $DATABASE
if [ $? != 0 ]
then
{
	echo "Couldn't create the database. Check my assumptions that I listed and then re-run this script."
	exit 1
} fi

echo "Importing database schema\n"
psql $DATABASE < postgresql.sql
if [ $? != 0 ]
then
{
	echo "Couldn't import the database. Check my assumptions that I listed and then re-run this script."
	exit 1
} fi
echo "All Done. Enjoy!\n"