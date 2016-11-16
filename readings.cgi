#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
PATH=.:$PATH
READINGS=readings.csv

QUERY_STRING=$(printf "${QUERY_STRING//%/\\x}")

eval ${QUERY_STRING//\&/ }

optlist ()
{
	opt=$1 list="" all=""
	print $QUERY_STRING | tr '&' '\n' | while read x
	do
		if [[ $x == $opt=* ]]; then
			v=${x##*=} list+=" $v"
			[ "$v" = "All" ] && all="y"
		fi
	done

	if [ "$all" ]; then
		list=$(print $(vals.sh $opt))
	else
		list=${list# }
	fi

	print ${list// /,}
}

Ulist=$(optlist User) Rlist=$(optlist Reading)

if [[ $(cols.sh User) -lt $(cols.sh Reading) ]]; then
	select=$(print {$Ulist},{$Rlist})
else
	select=$(print {$Rlist},{$Ulist})
fi

select=${select//\{/} select=${select//\}/}

case "$Action" in

Plot)
	print "Content-type: image/png\n"

	graphs=$(print $select | wc -w)
	(( --graphs ))

	(
	cat - <<-EOF
	set term png
	set datafile separator ","
	set timefmt "%Y-%m-%d_%H-%M-%S"
	set xdata time
	plot for [i=0:$graphs] "-" using $(DELIM=: cols.sh DateTime Value) with linespoints title columnheader
	EOF

	for s in $select
	do
		print "${s/,/-}"
		grep "${s/,/,.*}," $READINGS | sort -t',' -k$(DELIM=, cols.sh DateTime)
		print "e"
	done

	) | gnuplot
	;;

List)
	print "Content-type: text/html\n"
	print "<html>"
	print "<form action=$SCRIPT_NAME>"
	print "<input type=submit value=Delete>"
	print "<input type=hidden name=Action value=Delete>"
	print "<table border=1>"

	print "<tr>"
	for c in $(cols.sh)
	do
		print "<th>$c</th>"
	done
	print "<th>Delete</th>"
	print "</tr>"

	for s in $select
	do
		grep "${s/,/,.*}," $READINGS
	done | sort -r -t',' -k$(DELIM=, cols.sh DateTime) | while read x
	do
		print "<tr>"
			for c in ${x//,/ }
			do
				print "<td>$c</td>"
			done
		print "<td><input type=checkbox name=Key value=$c></td>"
		print "</tr>"
	done
	print "</table>"
	print "</form>"
	print "</html>"
;;

Delete)
	Klist=$(optlist Key) Klist=",${Klist//,/\$\|,}$"
	print "Content-type: text/html\n"
	print "<html>"
	print "<pre>"
	print "Deleted: $Klist"
	egrep "$Klist" $READINGS
	egrep -v "$Klist" $READINGS >$READINGS.tmp; mv $READINGS.tmp $READINGS
	print "</pre>"
	print "</html>"
;;

esac
