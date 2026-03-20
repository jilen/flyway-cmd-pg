# Flyway-PG

Lightweight Flyway distribution for PostgreSQL only.

## Why?

The official Flyway commandline distribution is **500MB+**. This version strips it down to **under 10MB** by only including PostgreSQL support.

## What's included

- Flyway Core (v12.1.1)
- PostgreSQL database support
- PostgreSQL JDBC driver

## Usage

Same as the official Flyway CLI:

```bash
flyway -url=jdbc:postgresql://localhost:5432/mydb -user=postgres -password=secret migrate
```

## Build

```bash
./mill commandline.dist
```

The output zip will be at `out/commandline/dist.dest/bundle.zip`
