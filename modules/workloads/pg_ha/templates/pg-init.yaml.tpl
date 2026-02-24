#cloud-config
ssh_pwauth: true

write_files:
  - path: /opt/postgres_setup.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      export PGPASSWORD="${pg_password}"
      echo "Setting up Postgres node (Primary: ${is_primary})"
      # ... installation and replication scripts (pg_basebackup, recovery.conf) would go here

runcmd:
  - apt-get update
  - apt-get install -y postgresql-15
  - /opt/postgres_setup.sh
