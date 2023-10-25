setup
{

  CREATE TABLE parent (
	parent_key	int		PRIMARY KEY,
	aux			text	NOT NULL
  );

  CREATE TABLE child (
	child_key	int		PRIMARY KEY,
	parent_key	int		NOT NULL REFERENCES parent
  );

  INSERT INTO parent VALUES (1, 'foo');
  INSERT INTO child VALUES (3,1);
}

teardown
{
  DROP TABLE parent, child;
}

session s1
setup     { SELECT set_config('babelfishpg_tsql.isolation_level_repeatable_read','pg_isolation',false);
  set transaction isolation level repeatable read; BEGIN TRAN; SET lock_timeout '500'; }
step s1s  { SELECT * from child; }
step s1i  { INSERT INTO child VALUES (1, 1); }
step s1u  { UPDATE parent SET aux = 'bar'; }
step s1d  { DELETE FROM child WHERE child_key = 3; }
step s1r  { ROLLBACK; }
step s1c  { COMMIT; }

session s2
setup	    { BEGIN TRAN; SET lock_timeout '10000'; }
step s2i	{ INSERT INTO child VALUES (2, 1); }
step s2u	{ UPDATE parent SET aux = 'baz'; }
step s2d  { DELETE FROM child WHERE child_key = 3; }
step s2c	{ COMMIT; }
step s2r  { ROLLBACK; }

permutation s1i s2i s1c s2c
permutation s1i s2i s2c s1c
permutation s2i s1i s1c s2c
permutation s2i s1i s2c s1c
permutation s1i s2i s2c s1s s1c
permutation s1u s2u s1c s2c
permutation s2u s1u s2r s1c
permutation s2u s1u s1c s2c
permutation s1d s2d s1c s2c
permutation s2d s1d s1c s2c
permutation s2d s1d s2r s1c
permutation s1s s2i s2c s1s s1c
