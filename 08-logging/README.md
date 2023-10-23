# Lab 8

In this lab we will setup centralized logging.

## Task 1: Install InfluxDB

Follow the official guide: https://portal.influxdata.com/downloads/

Install version 1.8.10. Instructions are hidden behind "Are you interested in InfluxDB 1.x Open Source?"

## Task 2: Create pinger service on one of VMs

Find bash script "pinger.sh" in 08-files.

Place this script to file /usr/local/bin/pinger.

Create a service "pinger" that runs from user "pinger". Check 08-files for systemd service unit example. Place it into /etc/systemd/system/.

Don't forget to execute on systemd config change:

    systemctl daemon-reload

Docs: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_module.html.

Pinger script requires config file:

    /etc/pinger/pinger.conf

Example can be found in 08-files as well.

## Task 3: Add latency monitoring to main Grafana dashboard

Add new Grafana datasource: influxdb:\<pinger_db_name\>. It should be provisoned automaticaly via Grafana provisioning.

Use this datasource for new panel in dashboard from previous lab.

No ip addresses allowed.

## Task 4: Setup Telegraf

Install Telegraf on the same VM where InfluxDB is located. Docs: https://portal.influxdata.com/downloads/

Desired telegraf version is 1.28.2.

Installation steps can be done in "influxdb" role.

Configure Telegraph for only syslog input and only influxdb output. Hint:

    telegraf config --help

Use UDP as a transport.

## Task 5: Setup rsyslog

Configure rsyslog on all VMs to send all logs to Telegraf. Docs: https://github.com/influxdata/telegraf/blob/master/plugins/inputs/syslog/README.md

Configure rsyslog in `init` role.

Use UDP as a transport.

## Task 6: Create logging dashboard in Grafana

Add one more datasource: influxdb:telegraf

Import Grafana dashboard for Syslog: https://grafana.com/grafana/dashboards/12433-syslog/

Add new datasource and dashboard to Grafana provisioning.

## Task 7: Add InfluxDB monitoring

Install InfluxDB stats exporter: https://github.com/carlpett/influxdb_stats_exporter

Download binary from latest [release](https://github.com/carlpett/influxdb_stats_exporter/releases/tag/v0.1.1) to /usr/local/bin/.

Create new systemd service. Run it with user `prometheus` as all other exporter do. Describe the service in /etc/systemd/system/prometheus-influxdb-stats-exporter.service.

Add couple more panels to your `Main` Grafana dashboard:

- InfluxDB health (influxdb_exporter_stats_query_success)
- InfluxDB write rate (influxdb_write_write_ok)

Don't forget to update json in your Ansible repo!

## Task 8: Supress InfluxDB requests logging

By default InfluxDB logs every request, which floods the logs.

Add to \[http\] section of influxdb config:

    log-enabled = false
    write-tracing = false

Add to \[data\] section of influxdb config:

    query-log-enabled = false

## Expected result

Your repository contains these files and directories:

    ansible.cfg
    group_vars/all.yaml
    hosts
    infra.yaml
    roles/influxdb/tasks/main.yaml
    roles/pinger/tasks/main.yaml

Your repository also contains all the required files from the previous labs.

Your repository **does not contain** Ansible Vault master password.

Everything is installed and configured with this command:

	ansible-playbook infra.yaml

Running the same command again does not make any changes to any of the managed
hosts.

After playbook execution you should be able to see all logs in one Grafana dashboard.
