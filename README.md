# Grafana on docker-compose

- https://github.com/prometheus/client_python

## Folder structure

- **app** contains a sample python flask app behind a nginx proxy

- **grafana** contains the monitoring stack
    - `provisioning` folder contains all files to automatically provision resources in Grafana like data sources

- **iac** contains terraform configuration files to deploy the stack on a EC2 instance in AWS

- **monitoring-jobs** contains shell scripts and/or python scripts that push custom metrics to pushgateway periodically.

## Deploy locally
```bash
git clone https://github.com/andregri/docker-compose-grafana.git
docker-compose -f docker-compose-grafana/grafana/docker-compose.yaml up -d
docker-compose -f docker-compose-grafana/app/docker-compose.yaml up -d
```

## Deploy with Terraform on AWS
- First create a EC2 key pair named "kp"
- Launch terraform configuration:
```tf
terraform init
terraform apply
```

## Alerting example

- CPU usage:
```
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```
- Disk Usage
```
max(100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)) by (instance)
```

## Add a db to Grafana data sources to monitor custom data

You can add a data source connected to your db.

- Edit `grafana/docker-compose.yaml` to make sure grafana is in the same the network of the db
- Edit `grafana/provisioning/datasources.yaml`:
```yaml
apiVersion: 1

datasources:
  - name: MySQL
    type: mysql
    url: db:3306
    database: grafana
    user: grafana
    jsonData:
      maxOpenConns: 0 # Grafana v5.4+
      maxIdleConns: 2 # Grafana v5.4+
      connMaxLifetime: 14400 # Grafana v5.4+
    secureJsonData:
      password: ${GRAFANA_MYSQL_PASSWORD}
```

**PROS**:
- easy to setup

**CONS**:
- the refresh frequency depends on the frequecy of the dashboard

## Send data to pushgateway using a bash script

[Stackoverflow guide](https://stackoverflow.com/questions/37458287/how-to-run-a-cron-job-inside-a-docker-container) that explaiins how to execute a cronjob on a docker container.

[crontab.guru](https://crontab.guru) helps to understand cronjob format.

1. Create a shell script in `monitoring_jobs/scripts/` directory, for instance `mysql-count-records.sh`:
```bash
# Obtain the data
# Crontab can't read env variables from docker-compose... so parameters are hardcoded
RECORDS_COUNT=$(mysql --silent --host db --user root --password="$(cat /run/secrets/db-password)" --execute "SELECT COUNT(*) FROM blog" example)

# Keep only the last line that contains the query result
echo $RECORDS_COUNT | tail -1

# Send the data to pushgateway
echo "mariadb_blog_records_from_bash_total $RECORDS_COUNT" | curl --data-binary @- http://pushgateway:9091/metrics/job/bash
```

2. Add a cronjob to `monitoring_jobs/cron`
```bash
* * * * * bash /scripts/mysql-count-records.sh >> /var/log/cron.log 2>&1    # every minute
```

3. Setup `monitoring_jobs/Dockerfile` to install the required dependencies

4. Start the containers: `docker-compose up -d --build`

**PROS**:
- shell script pros

**CONS**:
- unable to read env variables from docker-compose
- complex to parse metrics for pushgateway
- readability

## Send data to pushgateway using a python script

1. Create a shell script in `monitoring_jobs/scripts/` directory, for instance `mysql-count-records.py`. Below, the code snippet to send a metric to pushgateway:
```python
def push_metric(metric):
    registry = CollectorRegistry()
    # Define the metric type as a Gauge: set metric name and description
    # Metric name must be unique!
    g = Gauge('mariadb_blog_records_from_python_total', 'Count of records in blog table', registry=registry)
    # Set the metric value
    g.set(metric)
    # Send the metric to pushgateway
    push_to_gateway('pushgateway:9091', job='python', registry=registry)
```
Prometheus [guideline](https://prometheus.io/docs/practices/naming) for naming metric.

2. Add a cronjob to `monitoring_jobs/cron`. See [crontab.guru](https://crontab.guru) to understand cronjob format
```bash
* * * * * python3 /scripts/mysql-count-records.py >> /var/log/cron.log 2>&1    # every minute
```

3. Setup `monitoring_jobs/Dockerfile` to install the required dependencies with pip

4. Start the containers: `docker-compose up -d --build`

**PROS**:
- python pros
- readability

**CONS**:

## configure smtp in Grafana

Modify smtp section in `/etc/grafana/grafana.ini`

```ini
[smtp]
enabled = true
host = smtp.example.it:25
user = mail@example.com
# If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
password = examplePassword3!
;cert_file =
;key_file =
;skip_verify = false
from_address = mail@example.com
from_name = Grafana
```
