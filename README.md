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

Next, let's go through a few examples to see how table locks work in action.


## Setting the stage

To follow along, you'll need a Snowflake account and a table for testing.

In the Snowflake console, open up two worksheets. Each worksheet creates it's own session. We can pretend that each worksheet is a data pipeline sending transactions to a Snowflake table.

<p align="center">
    <img src="images/3.png" width=300>
</p>

In one of the worksheets, execute the statements in the `code/table.sql` file. These statements will create a `table_locks` table and populate it with a few records.

```sql
CREATE OR REPLACE TABLE table_locks (
    id int,
    msg string,
    last_modified date
);

INSERT INTO table_locks
VALUES
    (1, 'hello', '2023-01-01'),
    (2, 'hi', '2023-01-02'),
    (3, 'hola', '2023-01-03');
```

> You will have to choose a database and schema in the worksheet context so that Snowflake knows where to create the table.
> 
> Alternatively, you can use the fully qualified table name in the statements (e.g. `CREATE OR REPLACE TABLE DATABASE.SCHEMA.TABLE_LOCKS`)


## Read vs Read

We shouldn't worry too much about read-only transactions. Again, the only isolation level offered by Snowflake is read-committed. This means that any `SELECT` statement will simply read the latest committed data. 

Run the statments in the `code/read_read.sql` file, in the order specified, in two different worksheets. The `SHOW TRANSACTIONS` and `SHOW LOCKS` commands will help us confirm the state of transactions and locks.

```sql

-- worksheet 1
BEGIN TRANSACTION; -- 1
SHOW TRANSACTIONS; -- 2
SELECT * FROM table_locks; -- 5
SHOW LOCKS; -- 6
COMMIT; -- 9
SHOW TRANSACTIONS; -- 10

-- worksheet 2
BEGIN TRANSACTION; -- 3
SHOW TRANSACTIONS; -- 4
SELECT * FROM table_locks; -- 7
SHOW LOCKS; -- 8
COMMIT; -- 11
SHOW TRANSACTIONS; -- 12

```

Here's what you should have seen...
- Although transactions belong to a single session, they are visible to other sessions using the `SHOW TRANSACTION` statement.
- `SELECT` statements do not acquire any locks.
- Two read-only transactions do not affect what each other sees.


## Read vs Insert

In this example, one session will try to read from our table while another will attempt to insert new rows into the same table.

Similar to our previous example, run the statements in the `code/read_insert.sql` file.

```sql

-- worksheet 1
BEGIN TRANSACTION; -- 1
SHOW TRANSACTIONS; -- 2
INSERT INTO table_locks -- 6
VALUES (4, 'howdy', '2023-01-04');
SHOW LOCKS; -- 7
COMMIT; -- 10

-- worksheet 2
BEGIN TRANSACTION; -- 3
SHOW TRANSACTIONS; -- 4
SELECT * FROM table_locks;  -- 5
SHOW LOCKS; -- 8
SELECT * FROM table_locks; -- 9
SELECT * FROM table_locks; -- 11
COMMIT; -- 12

```

Things get interesting at the 6th step. The first session acquires a lock when inserting a new record. However, the second session is still able to read from the table in the 9th step despite seeing the lock from the first session. What gives?

As mentioned before, we don't have to worry too much about locks when reading from a table. Snowflake simply returns the latest committed data at the time of your `SELECT` statement. In the above example, at step 6, the first session hasn't committed the new row. This means that the second session doesn't "see" the new row and returns the table in it's state before the first session began it's transaction. 

However, as confirmed by steps 7 and 8, the first session does indeed acquire a lock on the `table_locks` table. When inserting data into a Snowflake table, new micropartitions are created to store it. These new partitions are locked, not visible, and cannot be modified by other transactions while the lock is in effect. So, while the second session has access to the `table_locks` table, it cannot read the newly created partitions containing the new record until the first session commits it's changes (and releases the lock).

Re-run the statements in the `code/table.sql` file to revert the changes from this example.

## Read vs Update

Let's see what happens when we try to read from a table that is being updated by a different session.

Run the statements in the `code/read_update.sql` file.

```sql

-- worksheet 1
BEGIN TRANSACTION; -- 1
SHOW TRANSACTIONS; -- 2
UPDATE table_locks
    SET msg = 'bonjour'
    WHERE id = 3; -- 6
SHOW LOCKS; -- 7
COMMIT; -- 10

-- worksheet 2
BEGIN TRANSACTION; -- 3
SHOW TRANSACTIONS; -- 4
SELECT * FROM table_locks;  -- 5
SHOW LOCKS; -- 8
SELECT * FROM table_locks; -- 9
SELECT * FROM table_locks; -- 11
COMMIT; -- 12

```

The results are similar to those in the previous example. The modifed row is not visible to the second session's read statements until the first session commits. Also like the previous example, the lock is acquired on the new partition created for the modified row. The second session does not see this new uncommitted partition, but can still read from the old partition containing the original record with value `msg = 'hola'`. 


## Insert vs Insert


