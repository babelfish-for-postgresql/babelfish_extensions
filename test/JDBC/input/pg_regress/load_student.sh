echo "-----copy student table from /data/student.data-----"
PGPASSWORD=12345678 psql -U jdbc_user -d babelfish_db -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/student.data'
COPY master_dbo.student FROM :'filename';
EOF
echo "----- done -----"