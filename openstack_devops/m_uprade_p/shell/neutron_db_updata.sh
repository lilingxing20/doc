mysql -e "SHOW CREATE DATABASE neutron"
mysql -e 'DROP DATABASE IF EXISTS neutron; CREATE DATABASE IF NOT EXISTS neutron;'
mysql -e "SHOW CREATE DATABASE neutron"
mysql -e 'alter database neutron character set utf8;'
mysql -e "SHOW CREATE DATABASE neutron"
sed -i.bak '/INSERT INTO `agents` VALUES/d' /root/backup_mitaka_db/mitaka-neutron-db-backup.sql
mysql -uroot neutron < /root/backup_mitaka_db/mitaka-neutron-db-backup.sql
neutron-db-manage current
neutron-db-manage upgrade --expand
neutron-db-manage upgrade --contract
DBversion=`neutron-db-manage  current`
echo $DBversion
Dversion1=5c85685d616d
Dversion2=7d32f979895f
if [[ $DBversion =~ $Dversion1 && $DBversion =~ $Dversion2 ]];then
    echo "Neutron database upgrade successful"
fi
