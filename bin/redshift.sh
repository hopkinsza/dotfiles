#!/bin/sh
if ps axo comm | grep -qx redshift; then
	echo 'redshift already running' >&2
	exit 1
fi

bright=0.6
temp=4200

while getopts 123b:t: f; do
	case $f in
	1)
		bright=0.8
		temp=5000
		;;
	2)
		bright=0.7
		temp=4500
		;;
	3)
		bright=0.6
		temp=4200
		;;
	b)
		bright=$OPTARG
		;;
	t)
		temp=$OPTARG
		;;
	esac
done
shift $(( $OPTIND - 1 ))

# ft wayne: 41.08:-85.14
redshift -r -m randr -l '28.989:-82.686' -t ${temp}K:${temp}K -b ${bright}:${bright}
