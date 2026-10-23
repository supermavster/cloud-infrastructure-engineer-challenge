# Local testing

A disposable PostgreSQL 17 in Docker, the same major version the deployed RDS
instance runs, so the Lambda code can be exercised without an AWS account.

```bash
make local-up        # starts it on 127.0.0.1:5432 and creates local/.env from the example
make local-invoke    # runs the real handler once and prints the response
make function-integration   # the integration tests, using the variables in local/.env
make local-down      # stops it and discards the data
```

`make function-integration` needs the variables exported first:

```bash
set -a; . local/.env; set +a; make function-integration
```

The handler runs in your Python process, not in a Lambda emulator, and TLS is
off (`DB_SSL_MODE=disable`) because the local server has no certificate. What
this cannot show: the VPC, the NAT gateway, Secrets Manager, the RDS API
lookup (so `instance` is `null`) and TLS verification against the RDS
certificate. Those only exist once deployed.

The database listens on loopback only, its data lives in memory (`tmpfs`), and
`local/.env` is gitignored. Change `DB_PORT` there if 5432 is taken.
