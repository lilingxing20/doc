 openssl genrsa -out openstack.key 2048
 openssl req -new -key openstack.key -out openstack.csr
 openssl rsa -in openstack.key -out openstack_nopwd.key
 openssl x509 -req -days 365 -in openstack.csr -signkey openstack.key -out openstack.crt
 cat openstack.crt openstack.key | tee openstack.pem
