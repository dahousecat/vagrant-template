#!/bin/bash

# Import config file
. /vagrant/setup/config

# Safety checks
. /vagrant/scripts/safety_checks.sh


# Create lock file
ssh chimchim touch $LOCK_FILE

if [ "$CMS" = "drupal" ] && [ -n "$CHIMCHIM_SITE_ROOT" ]; then
  echo "Clear cache on staging"
  ssh chimchim cd $CHIMCHIM_SITE_ROOT && drush cc all
fi


# Make sure database name is in the config
if [ -n "$CHIMCHIM_DB_NAME" ]; then

  # Dump database on remote server
  DUMP_NAME="${SITE_NAME}_db.sql.gz"
  echo "Dumping staging database to /tmp/$DUMP_NAME"
  ssh chimchim "mysqldump --opt $CHIMCHIM_DB_NAME | gzip > /tmp/$DUMP_NAME"

  # Copy dump to local
  echo "Copy dump to local"
  rsync -auv chimchim:"/tmp/$DUMP_NAME" "/vagrant/sqldump/$DUMP_NAME"

  # Delete dump
  echo "Deleting dump on staging"
  ssh chimchim rm "/tmp/$DUMP_NAME"

  echo "Importing database"
  zcat "/vagrant/sqldump/$DUMP_NAME" | mysql devdb

fi

# Check files path is in confif
if [ -n "$CHIMCHIM_FILES_DIR" ] && [ -n "$LOCAL_FILES_DIR" ]; then
  echo "Copying files"
  rsync -auv --max-size=1m --exclude='*.mp3' --exclude='*.pdf' chimchim:"$CHIMCHIM_FILES_DIR" "$LOCAL_FILES_DIR"
fi

if [ "$CMS" = "drupal" ]; then
  echo "Clear cache on local"
  cd "/var/www/$SITE_NAME" && drush cc all
fi

# Remove lock
ssh chimchim rm $LOCK_FILE

echo "All done"
