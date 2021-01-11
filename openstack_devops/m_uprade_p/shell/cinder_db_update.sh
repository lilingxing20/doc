mysql -e 'DROP DATABASE IF EXISTS cinder; CREATE DATABASE IF NOT EXISTS cinder character set utf8;'
sed -i.bak '/INSERT INTO `services`/d' /root/backup_mitaka_db/mitaka-cinder-db-backup.sql
mysql -uroot cinder < /root/backup_mitaka_db/mitaka-cinder-db-backup.sql
cinder-manage db version

# 需操作更新cinder/db/sqlalchemy/migrate_repo/versions下数据库升级脚本文件为Ocata版
mv /usr/lib/python2.7/site-packages/cinder/db/sqlalchemy/migrate_repo/versions{,_bkpike}
git clone https://github.com/openstack/cinder.git -b stable/ocata
cp -r cinder/cinder/db/sqlalchemy/migrate_repo/versions /usr/lib/python2.7/site-packages/cinder/db/sqlalchemy/migrate_repo/
su -s /bin/sh -c "cinder-manage db sync" cinder
DBversion=`cinder-manage db version`
echo $DBversion
if [ $DBversion == 96 ];then
    echo "Cinder database upgrade Ocata successful"
fi

# 需操作恢复cinder/db/sqlalchemy/migrate_repo/versions下数据库升级脚本为Pike版
mv /usr/lib/python2.7/site-packages/cinder/db/sqlalchemy/migrate_repo/versions{,_bkocata}
mv /usr/lib/python2.7/site-packages/cinder/db/sqlalchemy/migrate_repo/versions{_bkpike,}
su -s /bin/sh -c "cinder-manage db sync" cinder
DBversion=`cinder-manage db version`
echo $DBversion
if [ $DBversion == 105 ];then
    echo "Cinder database upgrade Pike successful"
fi
