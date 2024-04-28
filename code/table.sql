/*
Use the following statements to create and
populate the sample table table_locks.
*/

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
