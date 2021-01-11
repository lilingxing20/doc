mysql -e 'DROP DATABASE IF EXISTS nova; CREATE DATABASE IF NOT EXISTS nova character set utf8;'
mysql -e 'DROP DATABASE IF EXISTS nova_api; CREATE DATABASE IF NOT EXISTS nova_api character set utf8;'
mysql -e 'DROP DATABASE IF EXISTS nova_cell0; CREATE DATABASE IF NOT EXISTS nova_cell0 character set utf8;'
mysql -e 'DROP DATABASE IF EXISTS nova_placement; CREATE DATABASE IF NOT EXISTS nova_placement character set utf8;'
sed -i.bak '/INSERT INTO `services`/d' /root/backup_mitaka_db/mitaka-nova-db-backup.sql
mysql -uroot nova < /root/backup_mitaka_db/mitaka-nova-db-backup.sql
mysql -uroot nova_api < /root/backup_mitaka_db/mitaka-novaapi-db-backup.sql
echo "Update nova_api database..."
rm -f /var/log/nova/nova-manage.log 
su -s /bin/sh -c "nova-manage api_db version" nova
su -s /bin/sh -c "nova-manage api_db sync" nova
DBversion=`nova-manage api_db version`
echo $DBversion
if [ $DBversion == 45 ];then
    echo "The nova_api database upgrade successful"
fi

echo "Create cell"
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova


echo "Update nova database..."
# 需操作替换nova/db/sqlalchemy/migrate_repo/versions目录下文件为N版本Nova代码
git clone https://github.com/openstack/nova.git -b newton-eol
mv /usr/lib/python2.7/site-packages/nova/db/sqlalchemy/migrate_repo/versions{,_bkpike}
cp -r nova/nova/db/sqlalchemy/migrate_repo/versions /usr/lib/python2.7/site-packages/nova/db/sqlalchemy/migrate_repo/
su -s /bin/sh -c "nova-manage db version" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage db online_data_migrations" nova
DBversion=`nova-manage db version`
if [[ $DBversion == 334 ]];then
    echo "The nova database upgrade Newton successful"
fi
# 需操作恢复nova/db/sqlalchemy/migrate_repo/versions目录下文件为P版本Nova代码
mv /usr/lib/python2.7/site-packages/nova/db/sqlalchemy/migrate_repo/versions{,_bknewton}
mv /usr/lib/python2.7/site-packages/nova/db/sqlalchemy/migrate_repo/versions{_bkpike,}
su -s /bin/sh -c "nova-manage db version" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage db online_data_migrations" nova
DBversion=`nova-manage db version`
if [[ $DBversion == 362 ]];then
    echo "The nova database upgrade Pike successful"
fi
