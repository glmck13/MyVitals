#!/bin/ksh

result=""

for c in ${*:-All}
do
case $c in
	User)		result+=" 1" ;;
	Reading)	result+=" 2" ;;
	Value)		result+=" 3" ;;
	DateTime)	result+=" 4" ;;
	Battery)	result+=" 5" ;;
	Key)		result+=" 6" ;;
	1)		result+=" User" ;;
	2)		result+=" Reading" ;;
	3)		result+=" Value" ;;
	4)		result+=" DateTime" ;;
	5)		result+=" Battery" ;;
	6)		result+=" Key" ;;
	*)		result+=" User Reading Value DateTime Battery Key" ;;
esac
done

result=${result#?} result=${result// /${DELIM:- }}
print $result
