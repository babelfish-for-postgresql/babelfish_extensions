echo "-----copy onek table from /data/onek.data-----"
psql -U jdbc_user -d jdbc_testdb -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/onek.data'
COPY master_dbo.onek FROM :'filename';
EOF
echo "----- done -----"