setup
{

  CREATE TABLE child (
	child_key	int		PRIMARY KEY,
	child_value	int		NOT NULL 
  );

  INSERT INTO child VALUES (1,5);
  INSERT INTO child VALUES (2,10);
}

teardown
{
  DROP TABLE child;
}

session s1
setup     { SELECT set_config('babelfishpg_tsql.isolation_level_serializable','pg_isolation',false);
  set transaction isolation level serializable; BEGIN TRAN; SET lock_timeout '500'; }
step s1s  { SELECT * from child ORDER BY child_value ASC; }
step s1u1 { UPDATE child SET child_value = 12 where child_key = 1; }
step s1u2 { UPDATE child SET child_value = 7 where child_value < 6 }
step s1i  { INSERT INTO child VALUES (3, 15); }
step s1c  { COMMIT; }

session s2
setup	  { SELECT set_config('babelfishpg_tsql.isolation_level_serializable','pg_isolation',false);
    set transaction isolation level serializable; BEGIN TRAN; SET lock_timeout '500'; }
step s2s  { SELECT * from child ORDER BY child_value ASC; }
step s2i  { INSERT INTO child VALUES (4, 20); }
step s2u1 { UPDATE child SET child_value = 20 WHERE child_key in (SELECT TOP 1 child_key FROM child ORDER BY child_value DESC) }
step s2u2 { UPDATE child SET child_value = 5 where child_value >= 6 }
step s2c  { COMMIT; }

permutation s1s s1u1 s2u1 s1c s2c s1s
permutation s1i s2i s1s s2s s2c s1c
permutation s1u1 s2u2 s1s s1c s2c