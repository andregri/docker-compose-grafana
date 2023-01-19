#!/bin/bash

# Obtain the data
# Crontab can't read env variables from docker-compose... so parameters are hardcoded
RECORDS_COUNT=$(mysql --silent --host db --user root --password="$(cat /run/secrets/db-password)" --execute "SELECT COUNT(*) FROM blog" example)

# Keep only the last line that contains the query result
echo $RECORDS_COUNT | tail -1

# Send the data to pushgateway
echo "mariadb_blog_records_from_bash_total $RECORDS_COUNT" | curl --data-binary @- http://pushgateway:9091/metrics/job/bash