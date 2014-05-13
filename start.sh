#!/bin/bash

pre_start_action() {
	
	# Cleanup previous sockets
	rm -f /run/mysqld/mysqld.sock

	# Valid directory access
	chown -R mysql.mysql /data
	chmod -R 775 /data
	chown -R mysql.mysql /log
	chmod -R 775 /log

	# Clear start up SQL commands
	echo "" > /setup.sql

	# Initialize data dir if empty
	files_in_data_dir=`ls -1 /data | wc -w`

	# Scheduling a password reset for the root user, both % and localhost are needed.
	if [ $files_in_data_dir = 0 ]; then
		echo "MariaDB initial setup" >> /log/mysql.log
		echo "~~~~~~~~~~~~~~~~~~~~~" >> /log/mysql.log
		echo "" >> /log/mysql.log
		mysql_install_db --user=mysql
		echo -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '1234' WITH GRANT OPTION;\n" >> /setup.sql
		echo -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '1234' WITH GRANT OPTION;\n" >> /setup.sql
	fi

}

post_start_action() {
  : # No op
}

wait_for_mysql_and_run_post_start_action() {
  # Wait for mysql to finish starting up first.
  while [[ ! -e /run/mysqld/mysqld.sock ]] ; do
      inotifywait -q -e create /run/mysqld/ >> /dev/null
  done

  post_start_action
}

pre_start_action

wait_for_mysql_and_run_post_start_action &

echo "MariaDB start" >> /log/mysql.log
echo "~~~~~~~~~~~~~" >> /log/mysql.log
echo "" >> /log/mysql.log

exec /usr/bin/mysqld_safe --skip-syslog --init-file=/setup.sql
