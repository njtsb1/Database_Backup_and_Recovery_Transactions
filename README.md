# Project Challenge: Creating Transactions, Performing Database Backup and Recovery

PART 1 – TRANSACTIONS

Objective:

In this challenge, you will deal with transactions to execute modifications to the database. Therefore, let's review how to execute a transaction. First, you need to disable MySQL's autocommit. Otherwise, each executed SQL statement will be committed.

CODE 1

This first transaction can be executed without using other resources such as procedures. In this way, you will execute query statements and modify data persisted in the database via transactions.

CODE 2

PART 2 - TRANSACTION WITH PROCEDURE

You will need to create another transaction; however, this one will be defined within a procedure. In this case, as in the example in class, there must be an error check. This check will result in a ROLLBACK, total or partial (SAVEPOINT).

CODE 3

PART 3 – BACKUP AND RECOVERY

Objective:

In this stage of the challenge, you will perform a backup of the e-commerce database. Perform the backup and recovery of the database;

- Use mysqdump to perform the backup and recovery of the e-commerce database;

- Perform backups of different databases and insert resources such as: procedures, events, and others.

- Add the backup file to GitHub along with the script;
