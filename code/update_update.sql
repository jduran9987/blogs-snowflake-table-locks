-- worksheet 1
BEGIN TRANSACTION; -- 1
SHOW TRANSACTIONS; -- 2
UPDATE table_locks
    SET msg = 'bonjour'
    WHERE id = 3; -- 5
SHOW LOCKS; -- 6
COMMIT; -- 9

-- worksheet 2
BEGIN TRANSACTION; -- 3
SHOW TRANSACTIONS; -- 4
UPDATE table_locks
    SET msg = 'howdy'
    WHERE id = 2; -- 7
SHOW LOCKS; -- 8
COMMIT; -- 10
