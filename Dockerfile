# MariaDB - Galera - HAProxy
#
# VERSION 0.0.1


FROM ubuntu
MAINTAINER Despegar Hotels PAM <hotels-pam-it@despegar.com>


# Set up software repositories
ADD etc/apt /etc/apt
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
RUN	apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
RUN	apt-get update


# Install MariaDB - Galera
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common rsync netcat-openbsd
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-galera-server galera


#### # Install Xtrabackup for Snapshot State Transfer
#### RUN DEBIAN_FRONTEND=noninteractive apt-get -y install percona-toolkit percona-xtrabackup
