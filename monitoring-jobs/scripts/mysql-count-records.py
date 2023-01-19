from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import mysql.connector


def db_connect():
    pf = open('/run/secrets/db-password', 'r')
    conn = mysql.connector.connect(
        user="root", 
        password=pf.read(),
        host="db", # name of the mysql service as set in the docker compose file
        database="example",
        auth_plugin='mysql_native_password'
    )
    pf.close()
    return conn


def count_records(conn):
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM blog')
    rec = []
    for c in cursor:
        rec.append(c[0])
    return int(rec[0])


def push_metric(metric):
    registry = CollectorRegistry()
    # Define the metric type as a Gauge: set metric name and description
    # Metric name must be unique!
    g = Gauge('mariadb_blog_records_from_python_total', 'Count of records in blog table', registry=registry)
    # Set the metric value
    g.set(metric)
    # Send the metric to pushgateway
    push_to_gateway('pushgateway:9091', job='python', registry=registry)


if __name__ == "__main__":
    conn = db_connect()
    count = count_records(conn)
    push_metric(count)