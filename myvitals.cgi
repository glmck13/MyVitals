#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.cfg
PATH=.:$PATH

print "Content-type: text/html\n"
print "<html>"
print "<pre>"

pids=""
while IFS='|' read App x
do
	pids+=" $(ps | grep $App | cut -c 1-6)"
done <$CONFIG

pids=$(print $pids)
[ "$pids" ] && kill $pids

print "Killed: $pids"
print "Current user: $(users.sh $(<userno.cfg))"
cat $CONFIG

print "</pre>"
print "</html>"

while IFS='|' read App x
do
	${App}.sh >/dev/null 2>&1 &
done <$CONFIG
