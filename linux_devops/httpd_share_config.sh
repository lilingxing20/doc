#!/usr/bin/env bash


# 关闭防火墙
systemctl status firewalld
systemctl stop firewalld
systemctl disabled firewalld
systemctl mask firewalld
firewall-cmd --state

# 关闭selinux
sed -i '/^SELINUX=.*/c SELINUX=disabled' /etc/selinux/config
setenforce 0

# 数据盘
mkdir /www
mkfs.ext4 /dev/sdb
mkfs.ext4 -L www /dev/sdb

echo "LABEL=www   /www                       ext4     defaults        0 0" >>/etc/fstab
mount -a
mkdir /www/share


# 安装 createrepo，http服务
yum install createrepo httpd -y


# 配置http目录共享
echo '#http share
Alias /share /www/share
<Directory "/www/share">
    Options Indexes FollowSymLinks
    IndexOptions NameWidth=* DescriptionWidth=* FoldersFirst
    IndexOptions SuppressIcon HTMLTable Charset=UTF-8 SuppressHTMLPreamble
    Order allow,deny
    Allow from all
    Require all granted
</Directory>
'>/etc/httpd/conf.d/share.conf

cp /etc/httpd/conf/httpd.conf{,.bak}

echo "
ServerName localhost
# 关闭版本号显示
ServerSignature Off
ServerTokens Prod
">>/etc/httpd/conf/httpd.conf

systemctl enable httpd.service
systemctl restart httpd.service

# 浏览器访问 http://172.16.134.215/share ,能访问即正常
