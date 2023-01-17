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