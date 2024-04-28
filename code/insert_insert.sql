/* Scenario 1 - Non overlapping */

-- worksheet 1
BEGIN TRANSACTION; -- 1
SHOW TRANSACTIONS; -- 2
INSERT INTO table_locks -- 6
VALUES (4, 'howdy', '2023-01-04');
select * from table_locks; -- 7
SHOW LOCKS; -- 8
SELECT * FROM table_locks -- 12
COMMIT; -- 13

-- worksheet 2
BEGIN TRANSACTION; -- 3
SHOW TRANSACTIONS; -- 4
SELECT * FROM table_locks; -- 9
INSERT INTO table_locks -- 10
VALUES (5, 'bonjour', '2023-01-05');
SELECT * FROM table_locks; -- 11
SELECT * FROM table_locks; -- 14
COMMIT; -- 12


/* Scenario 2 - Overlapping */
