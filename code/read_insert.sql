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
