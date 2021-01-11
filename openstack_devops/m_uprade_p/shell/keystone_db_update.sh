mysql -e 'DROP DATABASE IF EXISTS keystone; CREATE DATABASE IF NOT EXISTS keystone character set utf8;'
# PASS=$(grep ^connection /etc/keystone/keystone.conf | awk -F":" '{print $3}' | awk -F"@" '{print $1}')
# mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY ‘$PASS';"
# mysql -e "flush privileges;"
mysql -uroot keystone < /root/backup_mitaka_db/mitaka-keytone-db-backup.sql
keystone-manage db_version
su -s /bin/sh -c "keystone-manage db_sync" keystone
DBversion=`keystone-manage db_version`
echo $DBversion
if [ $DBversion == 109 ];then
    echo "Keystone database upgrade successful"
fi
