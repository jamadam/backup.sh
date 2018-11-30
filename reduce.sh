#!/bin/bash

while getopts d:m:t: OPT
do
    case $OPT in
        "d" ) days=$OPTARG ;;
        "m" ) months=$OPTARG ;;
        "t" ) mock_today=$OPTARG ;; # mock today in epoch
    esac
done

shift `expr $OPTIND - 1`

BACKUPDIR=$1

if [ -z "$BACKUPDIR" ]; then
    exit 1
fi

TODAY=$(date +'%s')

if [ ! -z "$mock_today" ]; then
    TODAY=$mock_today
fi

for entry in $BACKUPDIR/*
do
    base=$(basename "$entry")
    mtime=$(stat -f "%m" $entry 2> /dev/null) || mtime=$(stat -c %Y $entry)
    diff=$(($TODAY - $mtime))
    if [ -n "$months" ]; then
        if (($diff > $((60 * 60 * 24 * 31 * $months)))); then
            rm -rf "$entry"
        fi
    fi
    if [ -n "$days" ]; then
        if ((diff > $((60 * 60 * 24 * ($days + 1))))); then
            if [[ $base =~ [0-9][0-9][0-9][0-9][0-9][0-9]01T ]]; then
                continue
            fi
            rm -rf "$entry"
        fi
    fi
done
