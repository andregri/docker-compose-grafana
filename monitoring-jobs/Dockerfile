FROM ubuntu:latest

# Install dependencies for your scripts
RUN apt update && apt-get -y install mysql-client curl pip

# Install python dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Install cron
RUN apt-get update && apt-get -y install cron

# Copy all scripts to /scripts directory
COPY scripts/ /scripts
RUN chmod 0744 /scripts/*

# Copy cron file to the cron.d directory
COPY cron /etc/cron.d/cron
 
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/cron

# Apply cron job
RUN crontab /etc/cron.d/cron
 
# Create the log file to be able to run tail
RUN touch /var/log/cron.log
 
# Run the command on container startup
CMD cron && tail -f /var/log/cron.log