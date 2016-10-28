#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.cfg
USERNO=userno.cfg
KEY=key.cfg
INFO=info.csv
READINGS=readings.csv
PATH=.:$PATH

grep -i pressure $CONFIG | IFS='|' read x BPOPTS
eval $BPOPTS

typeset -i s d p

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
			"connect error:" { sleep 5; continue }
			timeout { continue }
		}
	}
	expect "> "

        send "char-read-hnd 0x0003\r"
        expect "> "

	send "char-write-req 0x002f 0100\r"
	expect "Characteristic value was written successfully"
	expect "> "

	expect "* 00"
	sleep 10
	EOF

	do

	if [[ $x == *descriptor:* ]]; then
		Device=$(print ${x##*:} | xxd -r -p)
		User=$(users.sh $(<$USERNO))
		print "Reading pressure for $User from $Device."
		espeak "Reading pressure for $User from $Device."

	elif [[ $x == *0x002e\ value:\ 20* ]]; then
		print ${x##*:} | read x xp x
		p=16#${xp}
		print "Pressure = $p"

	elif [[ $x == *0x002e* ]]; then
		print ${x##*:} | read x x xs x xd x x x xp x
		s=16#${xs} d=16#${xd} p=16#${xp}
		Key=$(<$KEY); (( ++Key ))
		print $Key >$KEY
		Date=$(date +"%Y-%m-%d_%H-%M-%S")
		Info="$User,BP,$s/$d[$p],$Date,$Key"
		print $Info >$INFO
		Info="$User,Systolic,$s,$Date,$Key"
		print $Info >>$READINGS
		Info="$User,Diastolic,$d,$Date,$Key"
		print $Info >>$READINGS
		Info="$User,Pulse,$p,$Date,$Key"
		print $Info >>$READINGS
		print "Your pressure is $s over $d. Your pulse is $p."
		espeak "Your pressure is $s over $d. Your pulse is $p."
	fi

	done
done
