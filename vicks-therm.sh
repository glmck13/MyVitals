#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.cfg
USERNO=userno.cfg
KEY=key.cfg
INFO=info.csv
READINGS=readings.csv
PATH=.:$PATH
SCRIPTNAME=${0%.*}

grep -i $SCRIPTNAME $CONFIG | IFS='|' read x HTPOPTS
eval $HTPOPTS

typeset -F2 f

getReading ()
{
	print ${1##*:} | read x0 x1 x2 x3 x4 x5
	print $x4 $x3$x2$x1 | fconvert
}

rm -f /tmp/$SCRIPTNAME.log

while true
do
	expect - <<-EOF  | while read x

	set timeout 100
	spawn gatttool -b ${HTPOPTS} -I
	expect "> "

	while true {
		send "connect\r"
		expect {
			"Connection successful" { break }
			"Error:" { sleep 5; exit }
			"connect error:" { sleep 5; exit }
			timeout { sleep 5; exit }
		}
	}
	expect "> "

	send "char-read-uuid 0x2a00\r"
	expect "> "

	send "char-write-req 0x0018 0100\r"
	expect "Characteristic value was written successfully"
	expect "> "

	send "char-write-req 0x0013 0200\r"
	expect "Characteristic value was written successfully"
	expect "> "

	expect "Indication"
	sleep 10
	EOF

	do

print "$x" >>/tmp/$SCRIPTNAME.log

	if [[ $x == *0x0003* ]]; then
		Device=$(print ${x##*:} | xxd -r -p)
		User=$(users.sh $(<$USERNO))
		print "Reading temperature for $User from $Device."
		espeak "Reading temperature for $User from $Device."

	elif [[ $x == *0x0017* ]]; then
		f=$(getReading "$x")
		print "Current reading = $f"

	elif [[ $x == *0x0012* ]]; then
		f=$(getReading "$x")
		Key=$(<$KEY); (( ++Key ))
		print $Key >$KEY
		Date=$(date +"%Y-%m-%d_%H-%M-%S")
		Info="$User,Temp,$f,$Date,$Key"
		print $Info >$INFO
		print $Info >>$READINGS
		print "Your temperature is $f degrees"
		espeak "Your temperature is $f degrees"

	elif [[ $x == *Invalid\ file\ descriptor* ]]; then
		x=${x%\)*} x=${x#*:}
		kill $x
	fi

	done
done
