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
}

teardown
{
  DROP TABLE parent, child;
}

session s1
setup		{  select set_config('babelfishpg_tsql.enable_snapshot_isolation_for_reapeatable_read','on',false);
  set transaction isolation level repeatable read; BEGIN TRAN; SET lock_timeout '500'; }
step s1t { Select current_setting('transaction_isolation'); }
step s1s { Select * from child; }
step s1i	{ INSERT INTO child VALUES (1, 1); }
step s1c	{ COMMIT; }

session s2
setup		{ BEGIN TRAN; SET lock_timeout '10000'; }
step s2i	{ INSERT INTO child VALUES (2, 1); }
step s2c	{ COMMIT; }

permutation s1i s1c s2i s2c
permutation s1i s2i s1c s2c
permutation s1i s2i s1c s2c
permutation s1i s2i s1c s2c
permutation s1i s2i s1c s2c
permutation s1i s2i s2c s1c
permutation s1i s2i s2c s1c
permutation s2i s1i s1c s2c
permutation s2i s1i s1c s2c
permutation s2i s1i s2c s1c
permutation s2i s1i s2c s1c
permutation s2i s1i s2c s1c
permutation s2i s1i s2c s1c
permutation s2i s2c s1i s1c
permutation s1t s1i s2i s2c s1s s1c
