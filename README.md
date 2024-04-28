# Understanding Snowflake Table Locks

Table locks are not just for DBAs. Data engineers must also understand how to manage concurrent transactions from multiple applications to the same database table. 

To follow along with this article, clone the following repo ...


## Table locks in Snowflake

Before jumping into locks, let's first state a few important definitions...

- **Session** - A state of information exchange between a client and Snowflake. A session begins after a user has successfully connected and authenticated with Snowflake.
- **Transaction** - A sequence of SQL statements processed as one atomic unit. In other words, either all or none of the statements succeed.
- **Isolation Level** - The degree to which a transaction must be isolated from the data modifications made by another transaction.
- **Read Committed** - Snowflake's only isolation level. Within a transaction, a statement only sees data that has been committed. 

When you create a connection to Snowflake, you start a session. Within that session, you can send transactions to Snowflake. Each transaction is associated with a single session; in other words, transactions cannot be shared across multiple sessions.

<p align="center">
    <img src="images/1.png" width=300>
</p>

Now, picture a scenario where many applications send transactions to the same Snowflake database throughout the day. What happens when some of those transactions target the same tables at the same time? If we are strictly reading from those tables, then there is nothing to worry about. However, we have to be careful when at least one of those transactions attempts to modify the target table.

This is where locks become important. Transactions acquire locks when they modify a table. These locks prevent other transactions from modifying the table until the lock is released. Most DML operations acquire locks. For example, updates, deletes, and merges cannot run in parallel across different transactions. On the other hand, multiple transactions that perform inserts and copy statements at the same time are allowed.

<p align="center">
    <img src="images/2.png" width=300>
</p>


## Preparing for examples



Head over to the Snowflake console and open up a few worksheets. Each worksheet creates it's own session. We can think of each worksheet as if they were a separate data pipeline attempting to interact with a Snowflake table.

<p align="center">
    <img src="images/3.png" width=300>
</p>

Our examples will need a table to send transactions to. Run the statements in `code/table.sql` to 1) create the `table_locks` table and 2) populate it with a few rows of data.

```sql
CREATE OR REPLACE TABLE table_locks (
    id int,
    msg string,
    last_modified date
);

INSERT INTO table_locks
VALUES
    (1, 'hello', 2023-01-01),
    (2, 'hi', 2023-01-02),
    (3, 'hola', 2023-01-03);
```
