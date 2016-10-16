#!/bin/ksh

PATH=.:$PATH
DEVICE=${1:?}

typeset -F2 f

getReading ()
{
	print ${1##*:} | read x0 x1 x2 x3 x4 x5
	print $x4 $x3$x2$x1 | fconvert
}

while true
do
	expect - <<-EOF  | while read x

	set timeout 100
	spawn gatttool -b ${DEVICE} -I
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

	if [[ $x == *0x0003* ]]; then
		name=$(print ${x##*:} | xxd -r -p)
		print "Reading temperature from $name..."
		espeak "Reading temperature from $name..."

	elif [[ $x == *0x0017* ]]; then
		f=$(getReading "$x")
		print "Current reading = $f"

	elif [[ $x == *0x0012* ]]; then
		f=$(getReading "$x")
		print "Final reading = $f"
		espeak "Your temperature is $f degrees"
	fi

	done
done
