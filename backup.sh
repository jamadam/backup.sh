#!/bin/bash

# backup.sh <destination-base> <taget-dir1> [<taget-dir2> ..]
# backup.sh /backup/content /var/www1 /var/www2

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

rsync -av --delete --link-dest=../$LASTBACKUP $TARGETS $TEMPDIR >> $LOGFILE 2>&1
code=$?

echo "`date` backup end" >> $LOGFILE

if [ $code -eq 0 -o $code -eq 24 ]; then
    mv $TEMPDIR $NEWBACKUP
else
    cat $LOGFILE | mail -s "BACKUP NG CODE IS $code" root
fi
