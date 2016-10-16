#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
PATH=.:$PATH
READINGS=readings.csv

f=$(vals.sh $*)

print "<option value=\"All\" selected>All</option>"

if [ "$f" ]; then
	for opt in $f
	do
		print "<option value=\"$opt\">$opt</option>"
	done
fi
