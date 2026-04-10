# Part 3 — Backup and Recovery with mysqldump (file: README_backup.md and example commands)

Objective: Practical commands to generate backups of the ecommerce database, multiple databases, including routines, events, and triggers, and how to restore them.

Backup commands (Linux/macOS/Windows WSL)
Backup of a single database (includes data and schema):

```bash
mysqldump -u root -p --databases ecommerce > ecommerce_backup_$(date +%F).sql
```

Backup including routines, events and triggers (recommended for DB with procedures/events):

```bash
mysqldump -u root -p --routines --events --triggers --databases ecommerce > ecommerce_full_backup_$(date +%F).sql
```

Backup of multiple banks (e.g. ecommerce and analytics):

```bash
mysqldump -u root -p --routines --events --triggers --databases ecommerce analytics > multi_db_backup_$(date +%F).sql
```

Backup of all banks (all DBs):

```bash
mysqldump -u root -p --routines --events --triggers --all-databases > all_databases_backup_$(date +%F).sql
```

Structure-only backup (no data):

```bash
mysqldump -u root -p --no-data --databases ecommerce > ecommerce_schema_$(date +%F).sql
```

Backup of data only (without CREATE TABLE):

```bash
mysqldump -u root -p --no-create-info --databases ecommerce > ecommerce_data_$(date +%F).sql
```

Backup compression to save space:

```bash
mysqldump -u root -p --routines --events --triggers --databases ecommerce | gzip > ecommerce_full_backup_$(date +%F).sql.gz
```

Restore/Recovery Commands

Restore from a simple SQL file:

```bash
mysql -u root -p < ecommerce_full_backup_2026-04-09.sql
```

Restore from a compressed file (.gz):

```bash
gunzip < ecommerce_full_backup_2026-04-09.sql.gz | mysql -u root -p
```

Restore only a specific database from a dump containing multiple databases:

Open the .sql file and extract the section of the desired database (or use sed/awk), or import the entire dump (if there are no name conflicts).

Simple example (extract between `-- Current Database: \ecommerce\`` and next `-- Current Database`):

```bash
awk '/^-- Current Database: `ecommerce`/,/^-- Current Database: /{print}' multi_db_backup.sql > ecommerce_only.sql
mysql -u root -p < ecommerce_only.sql
```

Restore only routines (procedures/functions) if necessary:

If the dump was generated with `--routines`, the routines will be in the file. To restore only routines, extract the `DELIMITER`/`CREATE PROCEDURE` sections and execute.

Privilege caution: the user restoring needs to have `CREATE ROUTINE` and `ALTER ROUTINE` privileges.

Best practices and observations
User and privileges: use a user with sufficient privileges to create objects (tables, routines, events). For security, prefer creating backups with a dedicated user.

Consistency: For databases with high activity, use `--single-transaction` (only for transactional engines like InnoDB) for consistent dumps without locking tables:

```bash
mysqldump -u root -p --single-transaction --routines --events --triggers --databases ecommerce > ecommerce_consistent.sql
```

Table locking: If using MyISAM, consider `--lock-tables`.

Testing restores: Always test the restore in a staging environment before production.

Git versioning: Do not commit very large backup files to Git (Git repositories are not ideal for large binaries). If the backup is small and required by the exercise, include the .sql (or .sql.gz) file and document the size. Alternatively: use Git LFS or store it in external storage and link to it in the README.
