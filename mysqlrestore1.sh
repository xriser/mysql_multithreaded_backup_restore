#!/bin/bash

DOW=`date +%w`
#echo $DOW
COMMIT_COUNT=0
COMMIT_LIMIT=6
count=0

bcp=/backups/r1.c8.net.ua


echo `date '+%d-%m-%Y %H:%M:%S'` --------------------------------------------- >> /var/log/mysqlrestore1.log
echo `date '+%d-%m-%Y %H:%M:%S'` Starting wget >> /var/log/mysqlrestore1.log

cd $bcp
wget -N ftp://user:pass@c8.net.ua/db/banner_$DOW.sql.tgz

echo `date` Unpacking >>/var/log/mysqlrestore1.log
cd /backups/r1.c8.net.ua
rm -rf ${bcp}/db/tmp/mysqldump/
tar xfv banner_$DOW.sql.tgz

#exit 1

echo `date` Starting mysqlrestore >>/var/log/mysqlrestore1.log
FILES=`ls -S ${bcp}/db/tmp/mysqldump/`
fc=`ls ${bcp}/db/tmp/mysqldump |wc -l`

cd $bcp/db/tmp/mysqldump/

for f in $FILES
do
    #mysqldump -h... -u... -p... --hex-blob --triggers ${DB} ${TB} | gzip > ${DB}_${TB}.sql.gz &

    mysql -h127.0.0.1 -uroot -ppass banner < $f &
    echo $f
    let "count++"
    echo `date` Restoring $count/$fc $f >>/var/log/mysqlrestore1.log

    COMMIT_COUNT=`ps axu |grep 'mysql -h127.0.0.1 -uroot -p' |grep -v grep |wc -l`

        while [ ${COMMIT_COUNT} -ge ${COMMIT_LIMIT} ]; do
              sleep 5
              COMMIT_COUNT=`ps axu |grep 'mysql -h127.0.0.1 -uroot -p' |grep -v grep |wc -l`
        done

done

        while [ ${COMMIT_COUNT} -gt 0  ]; do
              sleep 5
              COMMIT_COUNT=`ps axu |grep 'mysql -h127.0.0.1 -uroot -p' |grep -v grep |wc -l`
        done

echo `date` Restoring done >>/var/log/mysqlrestore1.log

#cd /db/tmp
#tar cfz /db/tmp/banner.tgz /db/tmp/1

#echo `date` Finished mysqldump >>/var/log/mysqldump1.log

