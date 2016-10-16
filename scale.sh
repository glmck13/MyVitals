#!/bin/ksh

MYVITALS=/var/www/html/MyVitals; cd $MYVITALS
CONFIG=myvitals.cfg
USERNO=userno.cfg
KEY=key.cfg
INFO=info.csv
READINGS=readings.csv
PATH=.:$PATH

set -A User $(users.sh)
Index=$(<$USERNO)
MaxIndex=${#User[*]}

grep -i scale $CONFIG | IFS='|' read x WIIOPTS SCALEOPTS
eval $SCALEOPTS

KGS_TO_POUNDS=2.20462

Calibrate=0.0

typeset -F2 Weight

State=IDLE Countdown=0

wiic-scale $WIIOPTS | while read Event
do

case $State in

MEASURE)
	if [[ $Event == WEIGHT* ]]; then
		w=${Event#*=}
		[[ $w -gt $Weight ]] && Weight=$w
		(( --Countdown ))
		if [[ $Countdown -le 0 ]]; then
			(( Weight = ($Weight - $Calibrate) * $KGS_TO_POUNDS ))
			espeak "${User[$Index]} please step off. Your weight is $Weight pounds!"
			State=IDLE Countdown=0
			Key=$(<$KEY); (( ++Key ))
			Info="${User[$Index]},Weight,$Weight,$(date +"%Y-%m-%d_%H-%M-%S"),$Key"
			print $Key >$KEY
			print $Info >$INFO
			print $Info >>$READINGS
		fi

	elif [[ $Event == TAP* ]]; then
		State=MEASURE

	elif [[ $Event == PUSH* ]]; then
		State=MEASURE
	fi
	;;

SETUP)
	if [[ $Event == WEIGHT* ]]; then
		(( --Countdown ))
		if [[ $Countdown -le 0 ]]; then
			espeak "Setup complete!"
			State=IDLE Countdown=0
		fi

	elif [[ $Event == TAP* ]]; then
		(( Index = ($Index + 1) % $MaxIndex ))
		espeak "User is ${User[$Index]}."
		State=SETUP Countdown=$SETUPIDLE
		print $Index >$USERNO

	elif [[ $Event == PUSH* ]]; then
		espeak "Setup complete!"
		State=IDLE Countdown=0
	fi
	;;

IDLE)
	if [[ $Event == WEIGHT* ]]; then
		Calibrate=${Event#*=}
		State=IDLE

	elif [[ $Event == TAP* ]]; then
		espeak "${User[$Index]} please step on scale!"
		State=MEASURE Countdown=$SAMPLES Weight=0.0

	elif [[ $Event == PUSH* ]]; then
		espeak "Setup mode.  User is ${User[$Index]}."
		State=SETUP Countdown=$SETUPIDLE
	fi
	;;

esac

done
