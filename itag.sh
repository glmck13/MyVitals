#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.cfg
USERNO=userno.cfg
KEY=key.cfg
INFO=info.csv
READINGS=readings.csv
PATH=.:$PATH
SCRIPTNAME=${0} SCRIPTNAME=${SCRIPTNAME##*/} SCRIPTNAME=${SCRIPTNAME%.*}

grep -i $SCRIPTNAME $CONFIG | IFS='|' read x ITAGOPTS
eval $ITAGOPTS

set -A User $(users.sh)
Index=$(<$USERNO)
MaxIndex=${#User[*]}

typeset -i b

rm -f /tmp/$SCRIPTNAME.log

while true
do
	expect - <<-EOF  | while read x

	set timeout 100
	spawn gatttool -b ${ITAGOPTS} -I
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

	send "char-write-req 0x0036 0100\r"
	expect "Characteristic value was written successfully"
	expect "> "

	expect "WARNING"
	sleep 5
	EOF

	do

print -- "$x" >>/tmp/$SCRIPTNAME.log

	if [[ $x == *Characteristic\ value/descriptor:* ]]; then
		Device=$(print ${x##*:} | xxd -r -p)
		print "$Device detected. User is ${User[$Index]}."
		espeak "$Device detected. User is ${User[$Index]}."

	elif [[ $x == *handle:\ 0x0030* ]]; then
		print ${x##*:} | read lo x
		b=16#${lo}
		print "Battery level = $b%"

	elif [[ $x == *Notification\ handle\ =\ 0x0035\ value:\ 01* ]]; then
		(( Index = ($Index + 1) % $MaxIndex ))
		print $Index >$USERNO
		print "User is ${User[$Index]}."
		espeak "User is ${User[$Index]}."

	elif [[ $x == *Invalid\ file\ descriptor* ]]; then
		print "Setup complete. Battery level is $b%."
		espeak "Setup complete. Battery level is $b%."
		x=${x%\)*} x=${x#*:}
		kill $x
	fi

	done
done
