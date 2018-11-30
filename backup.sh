#!/bin/bash

# backup.sh <destination-base> <taget-dir1> [<taget-dir2> ..]
# backup.sh /backup/content /var/www1 /var/www2

# Remove daily backups older than 10 days
# backup.sh -d 10 /backup/content /var/www1 /var/www2

# Remove monthly backups older than 2 months
# backup.sh -m 2 /backup/content /var/www1 /var/www2

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

while getopts d:m: OPT
do
    case $OPT in
        "d" ) days=$OPTARG ;;
        "m" ) months=$OPTARG ;;
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

rsync -av --delete --link-dest=../$LASTBACKUP $TARGETS $TEMPDIR >> $LOGFILE 2>&1
code=$?

echo "`date` backup end" >> $LOGFILE

if [ $code -eq 0 -o $code -eq 24 ]; then
    mv $TEMPDIR $NEWBACKUP
else
    cat $LOGFILE | mail -s "BACKUP NG CODE IS $code" root
fi

days_param=""
if [ -n "$days" ]; then
    days_param="-d $days"
fi

months_param=""
if [ -n "$days" ]; then
    months_param="-m $days"
fi

$SCRIPTPATH/reduce.sh $days_param $months_param $BACKUPDIR
