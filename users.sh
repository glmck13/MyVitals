#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.cfg
PATH=.:$PATH

grep -i users $CONFIG | IFS='|' read x x

set -A User $x

if [ "$*" ]; then
	print "${User[$*]}"
else
	print "${User[*]}"
fi
