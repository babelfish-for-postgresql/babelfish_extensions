import psycopg2

#format strings for logging
line_formatter = "*" * 30 + "{}" + "*" * 30
connect_server_formatter = " Connected to {} Server successfully!! "
close_connection_formatter = " Connection closed to {} Server successfully!! "

# make connection object using psycopg
class Db_Client_psycopg:
    def __init__(self, server_url, db_name, db_user, logger):
        self.server_url = server_url
        self.db_name = db_name
        self.db_user = db_user
        self.logger = logger
        self.cnxn = None
        try:
            self.cnxn = psycopg2.connect(host = self.server_url, user = self.db_user, dbname = self.db_name)
            self.cnxn.autocommit = True
            self.logger.info(line_formatter.format(connect_server_formatter.format(self.server_url)))           
        except Exception as e:
            self.logger.error(str(e))
            self.logger.error(line_formatter.format("Server Connection failed"))
        
        
    def get_cursor(self):
        try:
            return self.cnxn.cursor()
        except Exception as e:
            self.logger.error(str(e))
            self.logger.error(line_formatter.format("Error while closing the connection"))

    def commit(self):
        self.cnxn.commit()

    def rollback(self):
        self.cnxn.rollback()

    def set_autocommit(self, val):
        self.cnxn.autocommit = val
        
    def close(self):
        try:
            self.cnxn.close()
            self.logger.info(line_formatter.format(close_connection_formatter.format(self.server_url)))
        except Exception as e:
            self.logger.error(str(e))
            self.logger.error(line_formatter.format("Error while closing the connection"))
