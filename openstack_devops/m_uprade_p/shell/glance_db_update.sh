mysql -e 'DROP DATABASE IF EXISTS glance; CREATE DATABASE IF NOT EXISTS glance character set utf8;'
mysql -uroot glance < /root/backup_mitaka_db/mitaka-glance-db-backup.sql
glance-manage db_version
su -s /bin/sh -c "glance-manage db_sync" glance
DBversion=`glance-manage db_version`
echo $DBversion
if [ $DBversion == 109 ];then
    echo "Keystone database upgrade successful"
fi
