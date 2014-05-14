# MariaDB - Galera
#
# Steps to get a working Galera cluster:
# 
#   *   Build this image. Tag it something like 'maria-galera'. Build it builds, continue
#       up to the start node step.
#
#           $ # The dot at the end is mandatory
#           $ sudo docker build --rm --tag=maria-galera .
#
#   *   Prepare conf, data, and log directories for the first node.
#
#           $ mkdir -p /path/to/node1/conf
#           $ mkdir -p /path/to/node1/data
#           $ mkdir -p /path/to/node1/log
#
#   *   Copy the cluster.cnf to the node's conf directory.
#
#           $ cp conf/cluster.cnf /path/to/node1/conf
#
#   *   Edit the cluster.cnf file, set the root password you want to use in
#       the wsrep_sst_auth property. Make sure wsrep_cluster_address is 
#       configured to gcomm://
#
#           $ vi /path/to/node1/conf/cluster.cnf
#
#   *   Start the first node passing all directories and port mappings. 
#       Give it a proper name.
#       Notice how WSREP ports are mapped to the same numbers outside the container, 
#       this is because there is no way (read: "I couldn't find a way") to make WSREP 
#       listen on one port but tell its clients to connect to another.
#
#           $ sudo docker run   -v /path/to/node1/conf:/conf 
#                               -v /path/to/node1/data:/data
#                               -v /path/to/node1/log:/log 
#                               -p 10011:3306 
#                               -p 10012:10012
#                               -p 10014:10014
#                               -d -t --name=maria1 maria-galera
#
#   *   Connect to the node, change the root password to the same value you specified in 
#       cluster.cnf (initial password is 1234). Also check WSREP is active and create some
#       test database to verify later that replication worked.
#
#           $ mysql -p -h <ip> --protocol=TCP -P 10001 -u root
#           MariaDB [(none)]> set password for 'root'@'%' = password('whatever');
#           MariaDB [(none)]> set password for 'root'@'localhost' = password('whatever');
#           MariaDB [(none)]> show status like 'wsrep%';
#           MariaDB [(none)]> create database test;
#           MariaDB [(none)]> use test
#           MariaDB [test]> create table test (a int, b varchar(200), primary key(a));
#           MariaDB [test]> insert into test values (1, '1');
#           MariaDB [test]> \q
#
#   *   Create the conf, data, and log directories for all remaining nodes.
#   *   Copy the cluster.cnf from the first node to the conf directory of all remaining
#       nodes. For all remining nodes, the wsrep_cluster_address
#       property must be configured to gcomm://<external-ip-of-the-first-node>:<sst-port>
#       For the sample first node created in above, the property would be:
#           gcomm://external_ip:10012
#   
#   *   Start all remaining nodes.
#
#   *   Connect to the last node you started with the root password you configured in 
#       the first node and check that the test database is there.
#
#   *   Edit again all cluster.cnf files and set the wsrep_cluster_address property
#       to list all nodes in the cluster except itself. This is necessary to allow any node
#       other than the first one you created to be the donor in case a node goes out of sync.
#       The value should read something like this:
#           gcomm://<ext-ip-1>:<port-1>,<ext-ip-2>:<port-2>,...,<ext-ip-N>:<port-N>
#
#   *   Restart nodes one by one.
#
#           $ sudo docker restart mariaX
#
# VERSION 0.0.1a

FROM ubuntu
MAINTAINER Despegar Hotels PAM <hotels-pam-it@despegar.com>

# Set up software repositories
ADD etc/apt /etc/apt
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
RUN apt-get update
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

ADD start.sh /start.sh
RUN chmod +x start.sh

ENTRYPOINT ["/start.sh"]
