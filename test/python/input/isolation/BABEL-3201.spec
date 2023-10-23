setup
{

  create table dbcc_test_locks (a int identity,  b int);
  INSERT INTO dbcc_test_locks VALUES (5);
  INSERT INTO dbcc_test_locks VALUES (7);

}

teardown
{
    drop table dbcc_test_locks;
}

session s1
setup     { 
            BEGIN TRAN TR1;
          }
step s1dbcc_noreseed  { dbcc checkident(dbcc_test_locks, NORESEED) }
step s1dbcc_reseed_without_new_reseed_value { dbcc checkident(dbcc_test_locks, RESEED) }
step s1dbcc_reseed_with_new_value { dbcc checkident(dbcc_test_locks, RESEED, 10) }
step s1i  { INSERT INTO dbcc_test_locks VALUES (8); }
step s1s { SELECT * FROM dbcc_test_locks; }
step s1c  { COMMIT; }

session s2
setup	  { 
          BEGIN TRAN TR2;
        }
step s2s  { SELECT * from dbcc_test_locks; }
step s2i  { INSERT INTO dbcc_test_locks VALUES (9); }
step s2c  { COMMIT; }

# till TR1 is commited, TR2 should be able to insert/read data from table t2 in case of noreeseed
permutation s1dbcc_noreseed s2i s2s s1c s2c

# till TR1 is commited, TR-2 should be able to insert/read data from table t2 in case of reeseed without new value.
permutation s1dbcc_reseed_without_new_reseed_value s2i s2s s1c s2c

# till TR1 is commited, TR-2 should NOT be able to read data from table t2 in case of reeseed with new value.
permutation s1dbcc_reseed_with_new_value s2s s1c s2i s2s s2c

