# Lab 14

In this lab we will install secondary DNS to provide DNS high availability.

## Task 1. Change location of DNS zone file

In lab 5 you might be created zone files in `/etc/bind/` directory. This directory should be managed by root, Bind9 service doesn't have permissions to write there by default.

For files that should be changed by service there is a special directory: `/var/cache/`.

Make sure your zone database files are located inside `/var/cache/bind/`. Configuration files are still in `/etc/bind/`.

Why do we need to do that? We're going to stop managing database files with Ansible directly.

## Task 2. Generate DNS key

You need to generate DNS key that will be used to authenticate secondary on primary.

Keys are generated with command on DNS server or any other server where `tsig-keygen` exists. Example:

    tsig-keygen example.key

Key name in your case should be `transfer.key`.

Generated output should be added to `named.conf.options`.

Obviously, key secret is secret data, use Ansible Vault to store it in your repo.

For more detailed explanation check section `TSIG` in the docs: https://downloads.isc.org/isc/bind9/cur/9.16/doc/arm/Bv9ARM.pdf -> TSIG

## Task 3. Create secondary DNS

Install Bind9 on second VM.

Configuration file with global options will be the same for primary and secondary, file with zone configuration will be different. Check docs how to configure zone as secondary: https://downloads.isc.org/isc/bind9/cur/9.16/doc/arm/Bv9ARM.pdf -> Sample configurations -> An Authoritative-only Name Server.

On primary DNS allow zone transfer only for those who have `transfer.key` set. Section `TSIG` in the docs.

On secondary DNS configure to use `transfer.key` when sending requests to primary. Section `TSIG` in the docs.

After this step secondary should be able to resolve all your internal FQDNs. Command for checking:

    dig name[.domain] @secondary_dns_ip

Hint #1: Bind9 primary and secondary should be configured in one role. Role should be applied to group `dns_servers`, which includes groups `dns_secondary` and `dns_primary`. When you want to apply some task only to secondary, use conditions:

    when: inventory_hostname in groups['dns_secondary']

Hint #2: If you don't like hint #1, you can create host variable `dns_role` and execute tasks based on this value. For example:

    when: dns_role == 'secondary'

## Task 4. Update /etc/resolv.conf

/etc/resolv.conf now should contain IPs of both DNS servers.

Good idea to include `search` option there as well. In that case you don't need to specify your full domain every time. Template example:

    search {{ your_domain }}     // will be added to short names
    nameserver {{ ip }}   // should be a loop over all primary DNS
    nameserver {{ ip }}   // should be a loop over all secondary DNS

## Task 5. Rewrite Ansible bind role

Change the way how you create zone file and records.

Initial zone file since now should contain only minimum required set: SOA record, NS record for each DNS server and A record for each NS record.

All other records Bind9 will add there by itself. Problem that might happen with this approach: next Ansible run will overwrite the database file and delete all the records created by Bind9. Solution: database file should be uploaded by Ansible only if it's missing. If file already there, Ansible should not touch it. Check docs for template module how to achieve this: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html

In Bind9 configuration allow zone updates only for those who have `nsupdate.key` set. Generate it same way as `transfer.key` from task 2.
  
All other records should be added with Ansible nsupdate module. Docs: https://docs.ansible.com/ansible/latest/collections/community/general/nsupdate_module.html

Create A record for backup server in bind role.

## Task 6. Create records for your services

CNAME records:
- grafana           // Points to vm-name with Grafana
- influxdb          // Points to vm-name with InfluxDB
- lb1, lb2          // Points to vm-names with HAProxy
- mysql1, mysql2    // Points to vm-names with MySQL
- ns1, ns2          // Points to vm-names with Bind9
- prometheus        // Points to vm-name with Prometheus
- web1, web2        // Points to vm-names with Agama containers

Create them in the end of respective roles. For example, `grafana` cname should be created in last task of grafana role.

Switch services configuration to CNAMES where applicable, examples: Grafana datasources, logging destination, Agama mysql host, Prometheus targets, etc...

## Task 7. Create PTR records for your VMs

Add new zone to your DNS servers: `168.192.in-addr.arpa`. It should have the same configuration as your main domain zone.

Reverse zone has the same mandatory fields: SOA, NS, A records for NS. PTR records look like this:

    42.166	IN	PTR	<vm1-name>.<your-domain>.
    43.31	IN	PTR	<vm2-name>.<your-domain>.

Docs: https://downloads.isc.org/isc/bind9/cur/9.16/doc/arm/Bv9ARM.pdf as usual.

Hint: Dot at the end of your FQDN is very important. Recheck lectures 5 and 14 if not sure why.

## Task 8. Grafana dashboard

Make sure that secondary DNS metrics are gathered by Prometheus.

Add secondary DNS graphs to your Grafana dashboard (same as for primary DNS).

## Post task

Create a file `name.txt` in the root of your repo with this content:

    real name:github username:discord username

Example:

    Roman Kuchin:romankuchin:RomanK

*Wrong*:

    real name: Roman Kuchin
    github username: romankuchin

*Wrong as well*:

    real name: Roman Kuchin username: romankuchin

## Expected result

Your repository contains these files:

    infra.yaml
    roles/bind/tasks/main.yaml
    name.txt
