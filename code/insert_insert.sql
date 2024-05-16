/* Scenario 1 - Non overlapping */

-- worksheet 1
BEGIN TRANSACTION; -- 1
SHOW TRANSACTIONS; -- 2
INSERT INTO table_locks
VALUES (4, 'howdy', '2023-01-04'); --5
SELECT * FROM table_locks; -- 6
SHOW LOCKS; -- 7
SELECT * FROM table_locks -- 11
COMMIT; -- 12

-- worksheet 2
BEGIN TRANSACTION; -- 3
SHOW TRANSACTIONS; -- 4
SELECT * FROM table_locks; -- 8
INSERT INTO table_locks
VALUES (5, 'bonjour', '2023-01-05'); -- 9
SELECT * FROM table_locks; -- 10
SELECT * FROM table_locks; -- 13
COMMIT; -- 14


/* Scenario 2 - Overlapping */

-- worksheet 1
BEGIN TRANSACTION; -- 1
SHOW TRANSACTIONS; -- 2
INSERT INTO table_locks
VALUES (4, 'howdy', '2023-01-04'); --5
SELECT * FROM table_locks; -- 6
SHOW LOCKS; -- 7
SELECT * FROM table_locks -- 11
COMMIT; -- 12

-- worksheet 2
BEGIN TRANSACTION; -- 3
SHOW TRANSACTIONS; -- 4
SELECT * FROM table_locks; -- 8
INSERT INTO table_locks
VALUES (4, 'bonjour', '2023-01-05'); -- 9
SELECT * FROM table_locks; -- 10
SELECT * FROM table_locks; -- 13
COMMIT; -- 14
