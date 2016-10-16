#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
PATH=.:$PATH
READINGS=readings.csv

cut -f $(cols.sh $*) -d',' $READINGS | sort | uniq
