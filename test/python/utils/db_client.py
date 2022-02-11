import pyodbc 
import pymssql

#format strings for logging
line_formatter = "*" * 30 + "{}" + "*" * 30
connect_server_formatter = " Connected to {} Server successfully!! "
close_connection_formatter = " Connection closed to {} Server successfully!! "

#make connection object using pyodbc
class Db_Client_pyodbc:
	
	def __init__(self,provider, server_url, port, db_name, db_user, db_pass, logger):
		
		self.provider=provider   
		self.server_url = server_url
		self.port = port
		self.db_name = db_name
		self.db_user = db_user
		self.db_pass = db_pass
		self.logger = logger
		self.cnxn = None
		try:
			self.cnxn = pyodbc.connect('DRIVER={};SERVER={},{};DATABASE={};UID={};PWD={}'.format(self.provider,self.server_url, str(self.port), self.db_name, self.db_user, self.db_pass), autocommit = True)
			self.logger.info(line_formatter.format(connect_server_formatter.format(self.server_url)))
		except Exception as e:
			
			self.logger.error(str(e))
			self.logger.error(line_formatter.format("Server Connection Failed"))
		
		
	def get_cursor(self):
		try:
			return self.cnxn.cursor()
		except Exception as e:
			self.logger.error(str(e))
			self.logger.error(line_formatter.format("Unexpected error in connection"))

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
	
	def set_isolation(self, val):
		self.cnxn.setattr(pyodbc.SQL_ATTR_TXN_ISOLATION, val)

#make connection object using pymssql
class Db_Client_pymssql:
	def __init__(self, server_url, port, db_name, db_user, db_pass, logger):
		self.server_url = server_url
		self.port = port
		self.db_name = db_name
		self.db_user = db_user
		self.db_pass = db_pass
		self.logger = logger
		self.cnxn = None
		try:
			self.cnxn = pymssql.connect(server = self.server_url, port = self.port, user = self.db_user, password = self.db_pass, database = self.db_name, autocommit = True)
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








