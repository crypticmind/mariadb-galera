# MariaDB - Galera
#
# Steps to get a working Galera cluster:
# 
#	* 	Build this image. Tag it something like 'maria-galera'.
#
#			$ # The dot at the end is mandatory
#			$ sudo docker build --rm --tag=maria-galera .
#
#	* 	Prepare conf, data, and log directories for the first node.
#
#			$ mkdir -p /path/to/node1/conf
#			$ mkdir -p /path/to/node1/data
#			$ mkdir -p /path/to/node1/log
#
#	* 	Copy the cluster.cnf to the  node's conf directory.
#
#			$ cp conf/cluster.cnf /path/to/node1/conf
#
#	* 	Edit the cluster.cnf file, set the root password you want to use in
#		the wsrep_sst_auth property. Make sure wsrep_cluster_address is 
#		configured to gcomm://
#
#			$ vi /path/to/node1/conf/cluster.cnf
#
#	* 	Start the first node passing the three directories and the MariaDB 
#		server port mapping, in background. Give it a proper name.
#			
#			$ sudo docker run	-v /path/to/node1/conf:/conf \
#								-v /path/to/node1/data:/data \
#								-v /path/to/node1/log:/log \
#								-p 10001:3306 -d -t --name=maria1 maria-galera
#
#	* 	Connect to the node, change the root password to the same value you specified in 
#		cluster.cnf (initial password is 1234). Also create some test database to verify
#		later that replication worked.
#
#			$ mysql -p -h localhost --protocol=TCP -P 10001 -u root
#			MariaDB [(none)]> set password for 'root'@'%' = password('whatever');
#			MariaDB [(none)]> set password for 'root'@'localhost' = password('whatever');
#			MariaDB [(none)]> create database test;
#			MariaDB [(none)]> use test
#			MariaDB [test]> create table test (a int, b varchar(200), primary key(a));
#			MariaDB [test]> insert into test values (1, '1');
#			MariaDB [test]> \q
#
#	* 	Take note of the IP address of the node. The others will request to synchronize 
#		against it.
#
#			$ sudo docker inspect maria1 | grep IPAddress
#
#	* 	Create the conf, data, and log directories for all remaining nodes.
#	* 	Copy the cluster.cnf from the first node to the conf directory of all remaining
#		nodes. For all remining nodes, the wsrep_cluster_address
#		property must be configured to gcomm://<ip-of-the-first-node>
#	
#	*	Start all remaining nodes.
#
#	*	Connect to the last node you started with the root password you configured in 
#		the first node, also check that the test database should be there already.
#
#
# VERSION 0.0.1a

FROM ubuntu
MAINTAINER Despegar Hotels PAM <hotels-pam-it@despegar.com>

# Set up software repositories
ADD etc/apt /etc/apt
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
RUN	apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
RUN	apt-get update
RUN cat /proc/mounts > /etc/mtab

# Install MariaDB - Galera
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pwgen inotify-tools python-software-properties software-properties-common rsync netcat-openbsd
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-galera-server galera
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install percona-toolkit percona-xtrabackup socat

# Tweak configuration
RUN cp /etc/mysql/my.cnf /etc/mysql/my.cnf~
ADD etc/mysql /etc/mysql
RUN chmod 644 /etc/mysql/my.cnf

# Set data and log directories
VOLUME ["/conf"]
VOLUME ["/data"]
VOLUME ["/log"]


EXPOSE 3306 4567

ADD start.sh /start.sh
RUN chmod +x start.sh

ENTRYPOINT ["/start.sh"]
