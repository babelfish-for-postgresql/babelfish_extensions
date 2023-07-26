echo "-----copy student table from /data/student.data-----"
psql -U jdbc_user -d jdbc_testdb -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/student.data'
COPY master_dbo.student FROM :'filename';
EOF
echo "----- done -----"