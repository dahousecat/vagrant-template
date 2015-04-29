#!/bin/bash

# Import config file
. /vagrant/setup/config

# Safety checks
. /vagrant/scripts/safety_checks.sh



function sync {

	# Create lock file
	ssh chimchim touch $LOCK_FILE

	if [ "$CMS" = "drupal" ]; then
		echo "Clear cache on local"
		cd "/var/www/$SITE_NAME" && drush cc all
	fi

	# Make sure database name is in the config
	if [ -n "$CHIMCHIM_DB_NAME" ]; then

		DUMP_NAME="${SITE_NAME}_db.sql.gz"

		echo "Dumping local database"
		mysqldump --opt devdb | gzip > "/vagrant/sqldump/$DUMP_NAME"

		echo "Copying database to staging"
		rsync -auv "/vagrant/sqldump/$DUMP_NAME" chimchim:"/tmp/$DUMP_NAME"

		echo "Importing database to staging"
		ssh chimchim "zcat /tmp/$DUMP_NAME | mysql $CHIMCHIM_DB_NAME"

		echo "Deleting dump on staging"
		ssh chimchim rm "/tmp/$DUMP_NAME"

	fi


	if [ -n "$CHIMCHIM_FILES_DIR" ] && [ -n "$LOCAL_FILES_DIR" ]; then
		echo "Copying files"
		rsync -rluv --max-size=1m -O "$LOCAL_FILES_DIR" chimchim:"$CHIMCHIM_FILES_DIR"
	fi

	
	if [ "$CMS" = "drupal" ] && [ -n "$CHIMCHIM_SITE_ROOT" ]; then
		echo "Clear cache on staging"
		ssh chimchim cd "$CHIMCHIM_SITE_ROOT" && drush cc all
	fi

	# Remove lock
	ssh chimchim rm $LOCK_FILE

	echo "All done"
}


# Are you sure?
read -r -p "This will copy your files and database over the top of staging. Are you sure you want to do this? [y/N] " response
case $response in
    [yY][eE][sS]|[yY])
        sync
        ;;
    *)
        exit
        ;;
esac

