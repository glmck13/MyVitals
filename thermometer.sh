#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.cfg
USERNO=userno.cfg
KEY=key.cfg
INFO=info.csv
READINGS=readings.csv
PATH=.:$PATH

grep -i thermometer $CONFIG | IFS='|' read x THERMOPTS DBUSOPTS
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
			espeak "Reading temperature for $User"
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
			espeak "Your temperature is $f degrees"
			State=IDLE
			Key=$(<$KEY); (( ++Key ))
			Info="$User,Temp,$f,$(date +"%Y-%m-%d_%H-%M-%S"),$Key"
			print $Key >$KEY
			print $Info >$INFO
			print $Info >>$READINGS
		fi
		;;
	esac
done
