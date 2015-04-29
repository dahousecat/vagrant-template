# Import database if one exists to be imported
if [ -f /vagrant/sqldump/database.sql ];
	then
		DATE=$(date +"%Y%m%d%H%M")
		mysql -uroot -ppassword devdb < /vagrant/sqldump/database.sql
		mv /vagrant/sqldump/database.sql /vagrant/sqldump/$DATE-imported.sql
fi
