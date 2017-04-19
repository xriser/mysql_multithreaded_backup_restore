#!/usr/local/bin/bash

# mysqldump parallel by tables for faster restoring
# by riser
#

COMMIT_COUNT=0
COMMIT_LIMIT=16

DOW=`date +%w`

echo ----------------------------------------------- >>/var/log/mysqldump1.log
echo `date` Starting mysqldump >>/var/log/mysqldump1.log

echo `date` Master position of binlog:  `/usr/local/bin/mysql  -Bse "show master status;"` >>/var/log/mysqldump1.log

rm -rf /db/tmp/mysqldump/
mkdir -p /db/tmp/mysqldump
cd /db/tmp/mysqldump

TBA=`/usr/local/bin/mysql -h127.0.0.1 -uuser -ppass -A --skip-column-names -e"SELECT CONCAT(table_schema,'.',table_name) FROM information_schema.tables WHERE table_schema IN ('banner')" | sed 's/\./ /g' | awk '{print $2}'`

for TB in $TBA
do
    #mysqldump -h... -u... -p... --hex-blob --triggers ${DB} ${TB} | gzip > ${DB}_${TB}.sql.gz &
    /usr/local/bin/mysqldump --skip-opt --add-drop-table --skip-add-locks --create-options --disable-keys --skip-lock-tables --quick --set-charset banner ${TB} > ${TB} &
    echo ${TB}
    echo `date` Dumping ${TB} >>/var/log/mysqldump1.log

    COMMIT_COUNT=`/bin/ps -x |grep "mysqldump --skip-opt" |grep -v grep |wc -l`

        while [ ${COMMIT_COUNT} -ge ${COMMIT_LIMIT} ]; do
              sleep 5
              COMMIT_COUNT=`/bin/ps -x |grep "mysqldump --skip-opt" |grep -v grep |wc -l`
        done

done

        while [ ${COMMIT_COUNT} -gt 0  ]; do
              sleep 5
              COMMIT_COUNT=`/bin/ps -x |grep "mysqldump --skip-opt" |grep -v grep |wc -l`
        done

echo `date` Dumping done >>/var/log/mysqldump1.log
echo `date` Starting compress >>/var/log/mysqldump1.log

## compress faster
tar cvf - /db/tmp/mysqldump | gzip -3 - > /db/bkp/db/banner_$DOW.sql.tgz

## very slowwwww
#tar cfz /db/bkp/db/banner_$DOW.sql.tgz /db/tmp/mysqldump

echo `date` Finished tgz >>/var/log/mysqldump1.log


