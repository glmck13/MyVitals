#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.conf
PATH=.:$PATH

print "Content-type: text/html\n"
print "<html>"
print "<pre>"

pids=""
while IFS='|' read App x
do
	case "$App" in

	\#greeting)
		espeak "$x" >/dev/null 2>&1
		;;

	\#*)
		;;

	*)
		pids+=" $(ps | grep $App | cut -c 1-6)"
		;;
	esac

done <$CONFIG

pids=$(
for p in $pids
do
	pstree $p -p -a | sed -e "s/.*,//" -e "s/ .*//"
done | sort | uniq
)
pids=$(print $pids)
[ "$pids" ] && kill $pids

print "Killed: $pids"
print "Current user: $(users.sh $(<userno.conf))"
cat $CONFIG

print "</pre>"
print "</html>"

while IFS='|' read App x
do
	case "$App" in

	\#*)
		;;

	*)
		${App}.sh >/dev/null 2>&1 &
		;;
	esac

done <$CONFIG
