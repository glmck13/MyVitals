#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.conf
USERNO=userno.conf
KEY=key.conf
INFO=info.csv
READINGS=readings.csv
PATH=.:$PATH
SCRIPTNAME=${0} SCRIPTNAME=${SCRIPTNAME##*/} SCRIPTNAME=${SCRIPTNAME%.*}

grep -i $SCRIPTNAME $CONFIG | IFS='|' read x BPOPTS
eval $BPOPTS

typeset -i s d p b

rm -f /tmp/$SCRIPTNAME.log

while true
do
	expect - <<-EOF  | while read x

	set timeout 100
	spawn gatttool -b ${BPOPTS} -I
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

        send "char-read-hnd 0x0003\r"
        expect "> "

	send "char-read-uuid 0x2a19\r"
	expect "> "

	send "char-write-req 0x002f 0100\r"
	expect "Characteristic value was written successfully"
	expect "> "

	expect "value: 0c"
	sleep 10
	EOF

	do

print "$x" >>/tmp/$SCRIPTNAME.log

	if [[ $x == *Characteristic\ value/descriptor:* ]]; then
		Device=$(print ${x##*:} | xxd -r -p)
		User=$(users.sh $(<$USERNO))
		print "Reading pressure for $User from $Device."
		espeak "Reading pressure for $User from $Device."

	elif [[ $x == *handle:\ 0x0036* ]]; then
		print ${x##*:} | read xb x
		b=16#${xb}
		print "Battery level = $b%"

	elif [[ $x == *Notification\ handle\ =\ 0x002e\ value:\ 20* ]]; then
		print ${x##*:} | read x xp x
		p=16#${xp}
		print "Pressure = $p"

	elif [[ $x == *Notification\ handle\ =\ 0x002e\ value:\ 0c* ]]; then
		print ${x##*:} | read x x xs x xd x x x xp x
		s=16#${xs} d=16#${xd} p=16#${xp}
		Key=$(<$KEY); (( ++Key ))
		print $Key >$KEY
		Date=$(date +"%Y-%m-%d_%H-%M-%S")
		Info="$User,BP,$s/$d[$p],$Date,$b,$Key"
		print $Info >$INFO
		Info="$User,Systolic,$s,$Date,$b,$Key"
		print $Info >>$READINGS
		Info="$User,Diastolic,$d,$Date,$b,$Key"
		print $Info >>$READINGS
		Info="$User,Pulse,$p,$Date,$b,$Key"
		print $Info >>$READINGS
		print "Your pressure is $s over $d. Your pulse is $p."
		espeak "Your pressure is $s over $d. Your pulse is $p."
		espeak "Battery level is $b%."

	elif [[ $x == *Invalid\ file\ descriptor* ]]; then
		x=${x%\)*} x=${x#*:}
		kill $x
	fi

	done
done
