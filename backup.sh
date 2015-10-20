#!/bin/bash

# backup.sh <destination-base> <taget-dir1> [<taget-dir2> ..]
# backup.sh /backup/content /var/www1 /var/www2

# Remove older backups than 10 dayes
# backup.sh -d 10 /backup/content /var/www1 /var/www2

while getopts d: OPT
do
    case $OPT in
        "d" ) days=$OPTARG ;;
    esac
done

shift `expr $OPTIND - 1`

BACKUPDIR=$1
shift
TARGETS=$@

mkdir -p $BACKUPDIR

LASTBACKUP=`ls -t $BACKUPDIR | grep -v "~" | head -1`
NEWBACKUP=$BACKUPDIR/`date +%Y%m%dT%H%M%S`
TEMPDIR=$NEWBACKUP~$$
mkdir $TEMPDIR

LOGFILE=$TEMPDIR/backup.log;
touch $LOGFILE
echo "`date` backup start" >> $LOGFILE

if [ ! -z "$days" ]; then
    find $BACKUPDIR/* -maxdepth 0 -type d -mtime +$days | xargs rm -rf
fi

rsync -av --delete --link-dest=../$LASTBACKUP $TARGETS $TEMPDIR >> $LOGFILE 2>&1
code=$?

echo "`date` backup end" >> $LOGFILE

if [ $code -eq 0 -o $code -eq 24 ]; then
    mv $TEMPDIR $NEWBACKUP
else
    cat $LOGFILE | mail -s "BACKUP NG CODE IS $code" root
fi
