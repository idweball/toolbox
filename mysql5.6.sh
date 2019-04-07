#!/bin/sh

[ $UID -ne 0 ] && \
echo "error: the script must be run with root" && \
exit 1

workspace=`cd $(dirname $0);pwd`

mysql_install_path=${MYSQL_INSTALL_PATH:-"/usr/local/mysql"}
mysql_data_path=${MYSQL_DATA_PATH:-"/data/mysql"}
mysql_run_user=${MYSQL_RUN_USER:-"mysql"}
mysql_run_group=${MYSQL_RUN_GROUP:-"mysql"}

[ -d "${mysql_install_path}" ] && \
echo "error: ${mysql_install_path} is already exists." && \
exit 1

[ -d "${mysql_data_path}" ] && \
echo "error: ${mysql_data_path} is already exists." && \
exit 1

yum install -y libaio-devel wget perl-Data-Dumper || exit 1

cd ${workspace}
tempdir=${workspace}/`mktemp -d temp.XXXX`

groupadd ${mysql_run_group}
useradd -g ${mysql_run_group} ${mysql_run_user} -s /sbin/nologin -M 

mkdir -p ${mysql_data_path} && \
chown -R ${mysql_run_group}:${mysql_run_user} ${mysql_data_path}

cd ${tempdir} &&
wget https://cdn.mysql.com//Downloads/MySQL-5.6/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz && \
tar -zxvf mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz && \
mv mysql-5.6.42-linux-glibc2.12-x86_64 ${mysql_install_path} && \
chown -R ${mysql_run_group}:${mysql_run_user} ${mysql_install_path} && \
cd ${mysql_install_path} && \
yes | cp support-files/mysql.server /etc/init.d/mysqld && \
chmod +x /etc/init.d/mysqld && \
./scripts/mysql_install_db --user mysql --basedir=${mysql_install_path} --datadir=${mysql_data_path} && \
rm -rf my.cnf
[ $? -ne 0 ] && cd ${workspace} && rm -rf ${tempdir} && exit 1


cat > /etc/my.cnf << EOF
[mysql]
socket = /tmp/mysql.sock
port = 3306

[mysqld]
basedir = ${mysql_install_path}
datadir = ${mysql_data_path}
user = ${mysql_run_user}
port = 3306
bind-address = 0.0.0.0
socket = /tmp/mysql.sock
EOF

echo "export PATH=${mysql_install_path}/bin:$PATH" > /etc/profile.d/mysql.sh

service mysqld start
if [ $? -eq 0 ];then
    echo ""
    echo -e "\033[31mMySQL5.6 Install Success!\033[0m"
    echo -e "\033[31m安装目录: ${mysql_install_path}\033[0m"
    echo -e "\033[31m数据目录: ${mysql_data_path}\033[0m"
    echo -e "\033[31m启动服务: service start mysqld\033[0m"
    echo -e "\033[31m停止服务: service stop mysqld\033[0m"
    echo ""
    rm -rf ${tempdir} && exit 0
fi
rm -rf ${tempdir} && exit 1
