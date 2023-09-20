echo "-----copy stud_emp table from /data/stud_emp.data-----"
PGPASSWORD=12345678 psql -U jdbc_user -d jdbc_testdb -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/stud_emp.data'
COPY master_dbo.stud_emp FROM :'filename';
EOF
echo "----- done -----"