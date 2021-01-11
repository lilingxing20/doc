source keystonerc_admin
openstack user create --domain default --password 123456 placement
openstack role add --project services --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://172.30.126.228:8778
openstack endpoint create --region RegionOne placement internal http://172.30.126.228:8778
openstack endpoint create --region RegionOne placement admin http://172.30.126.228:8778
