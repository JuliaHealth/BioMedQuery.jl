using MySQL
using BioMedQuery.DBUtils

dbname="test"

con = init_mysql_database("127.0.0.1", dbname, "root", "", true)
init_mysql_database(con, dbname, true)
init_mysql_database(con, dbname, false)

all_tables = select_all_tables(con)

pritntln(all_tables)
