# Grafana on docker-compose

## Folder structure

- **app** contains a sample python flask app behind a nginx proxy

- **grafana** contains the monitoring stack
    - `provisioning` folder contains all files to automatically provision resources in Grafana like data sources

- **iac** contains terraform configuration files to deploy the stack on a EC2 instance in AWS

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

## pushgateway example

```bash
echo "some_metric 3.14" | curl --data-binary @- http://pushgateway.example.org:9091/metrics/job/some_job
```

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