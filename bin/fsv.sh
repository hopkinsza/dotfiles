#!/bin/ksh

####
####
#### setup
####
####

usage () {
	cat >&2 <<-EOF
Usage: $0 [-c custom_logger] [-d] [-f file] [-L logger_flags]
           [-lo] [-p pri] [-r run_dir] command
	EOF
	exit 1
}
# like the C function errx(3)
errx () {
	ex="$1"; shift
	print -u2 "$0: $@"

	exit $ex
}

#
# be paranoid
#
umask 022

#
# exit on error
#
# TODO uncomment?
#set -e

#
# variables
#
# subdir to use, and files
my_dir=
service_pidfile=
log_fifo=

my_pid=$$
my_uid=`id -u`
child_pid=
logger_fsv_pid=

#
# variables relating to flags.
# flags with no argument are set to `y' or `n';
# flags that take an argument are given default values (often null)
#
debug=n
restart=y
#run_dir=/var/run/fsv
run_dir="/tmp/fsv-$my_uid"
in_file=/dev/null

dev_null=n

custom_logger=
logger_flags=
log=n
pri=


####
####
#### get args
####
####

while getopts 'c:df:L:lnop:r:' f; do
	case "$f" in
		c)
			custom_logger="$OPTARG"
			if [[ "$custom_logger" = *\ * ]]; then
				errx 2 "custom_logger cannot contain whitespace"
			fi
			log=y
			;;
		d)
			debug=y
			;;
		f)
			in_file="$OPTARG"
			;;
		L)
			logger_flags="$OPTARG"
			log=y
			;;
		l)
			log=y
			;;
		n)
			dev_null=y
			;;
		o)
			restart=n
			;;
		p)
			pri="$OPTARG"
			log=y
			;;
		r)
			run_dir="$OPTARG"
			;;
		?)
			usage
			;;
	esac
done
shift $(( $OPTIND - 1 ))


####
####
#### sanity checks, set variables (and debug functions) based on flags
####
####
if [ "$debug" = "y" ]; then
	# define debug functions; they are a no-op if debugging is not on
	db () {
		print -u2 "$my_pid: $@"
	}
	dbsec () {
		print -u2 "********"
		print -u2 "$my_pid: $@"
	}
	dbdot () {
		print -nu2 "$my_pid: $@... "
	}
	dbok () {
		if [ -z "$1" ]; then
			print -u2 "ok"
		else
			print -u2 "$@"
		fi
	}
else
	db    () { :; }
	dbsec () { :; }
	dbdot () { :; }
	dbok  () { :; }
fi

dbsec "sanity checks"
#
# can't run with no args
#
[ -z "$1" ] && usage

#
# sanity checks on $run_dir before making $my_dir
#
dbdot "checking existence and perms of run_dir $run_dir"
if [ -d "$run_dir" ] && [ -w "$run_dir" ]; then
	# good to go
	:
	dbok
elif mkdir -p "$run_dir"; then
	dbok "created"
else
	errx 2 "run_dir $run_dir doesn't exist or isn't writable"
fi

dbdot "creating my_dir"
my_dir="$run_dir/$1-fsv-$my_pid"
mkdir -p "$my_dir"
dbok "$my_dir"

dbdot "setting var service_pidfile"
service_pidfile="$my_dir"/service.pid
dbok "$service_pidfile"

#
# trap functions
#
# kill logger and child process if they exist,
# remove runtime files, then exit gracefully
cleanup () {
	dbsec 'cleanup'
	if [ -z "$logger_fsv_pid" ]; then
		# no logger; no need to kill
		:
	else
		kill $logger_fsv_pid
		kill -CONT $logger_fsv_pid
	fi
	if [ -z "$child_pid" ]; then
		dbdot "child is not running, no need to kill"
		db
	else
		dbdot "killing my child"
		dbok "goodnight sweet prince"
		kill $child_pid
		kill -CONT $child_pid
	fi

	# give logger process a second to cleanup
	#sleep 1
	# wait for all children to exit
	wait

	dbdot "removing service_pidfile $service_pidfile"
	rm "$service_pidfile"
	dbok

	if [ ! -z "$log_fifo" ]; then
		dbdot "removing log_fifo $log_fifo"
		rm "$log_fifo"
		dbok
	fi

	dbdot "removing my_dir $my_dir"
	rmdir "$my_dir"
	dbok

	exit 0
}
# ERR is the trap executed when a command returns non-zero, just before
# this shell exits due to set -e
trap cleanup INT TERM HUP ERR

#
# set up logger if necessary
#
if [ "$log" = y ]; then
	dbsec "setting up logger"
	dbdot "building var logger_cmd"
	logger_cmd=
	#
	# use custom logger, or logger(1) by default
	#
	if [ -z "$custom_logger" ]; then
		logger_cmd=logger
	else
		logger_cmd="$custom_logger"
	fi

	#
	# add flags
	#
	logger_cmd="$logger_cmd $logger_flags"
	[ ! -z "$pri" ] && logger_cmd="$logger_cmd -p $pri"
	dbok "$logger_cmd"

	#
	# set up the log-fifo
	#
	dbdot "creating log_fifo"
	log_fifo="$my_dir"/log-fifo
	mkfifo "$log_fifo"
	dbok "$log_fifo"

	#
	# set up a new fsv for the logger; its $run_dir will be
	# our $my_dir, and it reads from $log_fifo
	#
	dbdot "making new fsv instance for logger"
	# TODO uncomment
	#fsv -nr "$my_dir" -- $logger_cmd <$log_fifo &
	fsv -d -f "$log_fifo" -r "$my_dir" -- $logger_cmd &
	logger_fsv_pid=$!
	dbok "logger_fsv_pid: $logger_fsv_pid"
fi

#
# run
#
while :; do
	# run command in background so we can grab its pid,
	# with whatever logging redirection is necessary
	if [ "$log" = y ]; then
		"$@" >"$log_fifo" <"$in_file" 2>&1 &
	elif [ "$dev_null" = y ]; then
		"$@" >/dev/null   <"$in_file" 2>&1 &
	else
		"$@" <"$in_file" &
	fi
	child_pid=$!
	echo "$child_pid" > "$service_pidfile"

	# wait on the child. the exit code will be whatever the child exited
	# with; we have to "test" this value so the shell won't exit due to
	# set -e
	wait $child_pid && :

	# child has exited
	child_pid=

	if [ "$restart" = y ]; then
		sleep 1
	else
		kill $my_pid
	fi
done
