mariadb-galera
==============

A [Docker](https://www.docker.io) build file to construct a container of a MariaDB-Galera cluster node.

Steps to get a working Galera cluster:

1. Build the image. Tag it something like _maria-galera_. While it builds, continue up to the "Start the first node" step. 

    _(Mind the dot at the end of the command)_

        $ sudo docker build --rm --tag=maria-galera .

1. Prepare `conf`, `data`, and `log` directories for the first node.

        $ mkdir -p /path/to/node1/conf
        $ mkdir -p /path/to/node1/data
        $ mkdir -p /path/to/node1/log

1. Copy the cluster.cnf to the node's conf directory.

        $ cp conf/cluster.cnf /path/to/node1/conf

1. Edit the `cluster.cnf` file, set the root password you want to use in
the `wsrep_sst_auth` property. Make sure `wsrep_cluster_address` is 
configured to `gcomm://`

        $ vi /path/to/node1/conf/cluster.cnf

1. Start the first node passing all directories and port mappings. Give it a proper name. 

    Notice how WSREP ports are mapped to the same numbers outside the container, this is because there is no way (read: "I couldn't find a way") to make WSREP listen on one port but tell its clients to connect to another. 
    
    WSREP ports are all the ports you'll find in the `cluster.cnf` file: A gmcast port and SST receive port. If you happen to configure anything else whatsoever in MariaDB requiring another port, you'll have to publish it here as well.

        $ sudo docker run \
            -v /path/to/node1/conf:/conf \
            -v /path/to/node1/data:/data \
            -v /path/to/node1/log:/log \
            -p 10011:3306 \
            -p 10012:10012 \
            -p 10014:10014 \
            -d -t --name=maria1 maria-galera

1. Connect to the node, change the root password to the same value you specified in `cluster.cnf` (initial password is `1234`). Also check WSREP is active (look for wsrep_ready ON) and create some test database to verify later that replication worked.

        $ mysql -p -h <ip> --protocol=TCP -P 10011 -u root
        MariaDB [(none)]> set password for 'root'@'%' = password('whatever');
        MariaDB [(none)]> set password for 'root'@'localhost' = password('whatever');
        MariaDB [(none)]> show status like 'wsrep%';
        MariaDB [(none)]> create database test;
        MariaDB [(none)]> use test
        MariaDB [test]> create table test (a int, b varchar(200), primary key(a));
        MariaDB [test]> insert into test values (1, '1');
        MariaDB [test]> \q

1. Create the `conf`, `data`, and `log` directories for all remaining nodes.

1. Copy the `cluster.cnf` from the first node to the `conf` directory of all remaining nodes, changing the `wsrep_cluster_address` property to `gcomm://<external-ip-of-the-first-node>:<sst-port>`.
    
    For the sample first node created above, the property would be:
        
        gcomm://external_ip:10012

1. Start all remaining nodes.

1. Connect to the last node you started with the root password you configured in the first node and check that the test database is there.

1. Edit again all `cluster.cnf` files and set the `wsrep_cluster_address` property to list all nodes in the cluster except itself. This is necessary to allow any node other than the first one you created to be the donor in case a node goes out of sync.

    The value should read something like this:

        gcomm://<ext-ip-1>:<port-1>,<ext-ip-2>:<port-2>,...,<ext-ip-N>:<port-N>

1. Restart nodes one by one.

        $ sudo docker restart mariaX
