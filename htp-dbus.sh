#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.conf
USERNO=userno.conf
KEY=key.conf
INFO=info.csv
READINGS=readings.csv
PATH=.:$PATH
SCRIPTNAME=${0} SCRIPTNAME=${SCRIPTNAME##*/} SCRIPTNAME=${SCRIPTNAME%.*}

grep -i $SCRIPTNAME $CONFIG | IFS='|' read x THERMOPTS DBUSOPTS
eval $DBUSOPTS

typeset -F2 f

State=IDLE

dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez \
	/org/bluez${DBUSOPTS} \
	org.freedesktop.DBus.Properties.Get string:"org.bluez.Device1" string:"Name" | read x Device

print $Device

thermometer.py $THERMOPTS | while read x
do
	case "$x" in

	*measurement*)
		s=${x%% *}
		if [ "$State" = "IDLE" ]; then
			User=$(users.sh $(<$USERNO))
			espeak "Reading temperature for $User from $Device."
			State=READING
		fi
		if [ "$s" = "final" ]; then
			State=FINAL
		fi
		;;

	Mantissa:*)
		m=${x#*:}
		;;

	Exponent:*)
		e=${x#*:}
		;;

	Unit:*)
		;;

	Type:*)
		f=$(print $e $m | fconvert -d)
		print $s=$f
		if [ "$State" = "FINAL" ]; then
			State=IDLE
			Key=$(<$KEY); (( ++Key ))
			print $Key >$KEY
			Date=$(date +"%Y-%m-%d_%H-%M-%S")
			Info="$User,Temp,$f,$Date,?,$Key"
			print $Info >$INFO
			print $Info >>$READINGS
			espeak "Your temperature is $f degrees."
		fi
		;;
	esac
done
