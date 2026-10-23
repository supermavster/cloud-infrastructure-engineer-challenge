# RDS CA bundle

`global-bundle.pem` is the public certificate bundle AWS publishes for RDS, used
to verify the database's TLS certificate (`verify-full`).

- Source: https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
- SHA-256: `90a6f1a7978a1b1b096dca6c57511ca48d3b8cf052f8e704baf358f34ea2f21b`
- Contents: 114 public CA certificates, no private keys.

To refresh it, download the file again, update the checksum above and review
the diff.
