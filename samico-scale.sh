#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.cfg
USERNO=userno.cfg
KEY=key.cfg
INFO=info.csv
READINGS=readings.csv
PATH=.:$PATH
SCRIPTNAME=${0} SCRIPTNAME=${SCRIPTNAME##*/} SCRIPTNAME=${SCRIPTNAME%.*}

grep -i $SCRIPTNAME $CONFIG | IFS='|' read x SCALEOPTS
eval $SCALEOPTS

typeset -i w b
typeset -F1 f

rm -f /tmp/$SCRIPTNAME.log

while true
do
	expect - <<-EOF  | while read x

	set timeout 100
	spawn gatttool -b ${SCALEOPTS} -I
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

	expect "value: cb 01"
	sleep 20
	EOF

	do

print -- "$x" >>/tmp/$SCRIPTNAME.log

	if [[ $x == *Characteristic\ value/descriptor:* ]]; then
		Device=$(print ${x##*:} | xxd -r -p)
		User=$(users.sh $(<$USERNO))
		print "Reading weight for $User from $Device."
		espeak "Reading weight for $User from $Device."

	elif [[ $x == *handle:\ 0x0036* ]]; then
		print ${x##*:} | read lo x
		b=16#${lo}
		print "Battery level = $b%"

	elif [[ $x == *Notification\ handle\ =\ 0x002e\ value:\ ca* ]]; then
		print ${x##*:} | read x x hi lo x
		w=16#${hi}${lo} f=$w; (( f /= 10 ))
		print "Weight = $f kgs"

	elif [[ $x == *Notification\ handle\ =\ 0x002e\ value:\ cb* ]]; then
		print ${x##*:} | read x x hi lo x
		w=16#${hi}${lo} f=$w; (( f /= 10 ))
		Key=$(<$KEY); (( ++Key ))
		print $Key >$KEY
		Date=$(date +"%Y-%m-%d_%H-%M-%S")
		Info="$User,Weight,$f,$Date,$Key,$b"
		print $Info >$INFO
		print $Info >>$READINGS
		print "Your weight is $f pounds."
		espeak "Your weight is $f pounds."
		espeak "Battery level is $b%."

	elif [[ $x == *Invalid\ file\ descriptor* ]]; then
		x=${x%\)*} x=${x#*:}
		kill $x
	fi

	done
done
