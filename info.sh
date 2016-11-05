#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
PATH=.:$PATH
INFO=info.csv

eval IFS="," read $(cols.sh) < $INFO

cat - <<EOF
<h1>
$User $Reading=$Value
</h1>
DateTime=$DateTime
Battery=$Battery%
EOF
