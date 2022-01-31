import pyodbc
from compare_results import handle_exception_in_file
from utils.config import config_dict as cfg

#function to perform TestAuth
def py_authentication(file_writer, query, logger):
    result = query.split("#!#")

    connection_properties_babel = {}

    if cfg["driver"] == "pyodbc":
        connection_properties_babel["serverName"] = cfg["fileGenerator_URL"]
        connection_properties_babel["portNumber"] = cfg["fileGenerator_port"]
        connection_properties_babel["database"] = cfg["fileGenerator_databaseName"]
        connection_properties_babel["user"] = cfg["fileGenerator_user"]
        connection_properties_babel["password"] = cfg["fileGenerator_password"]

        other_prop = ""
        connection_string_babel = create_connection_string(result, connection_properties_babel, other_prop)
        logger.info('Establishing connection with the connection string: {}'.format(connection_string_babel))

        try:
            file_writer.write(query)
            file_writer.write("\n")

            babel_cnxn = pyodbc.connect(connection_string_babel)

            file_writer.write("~~SUCCESS~~")
            file_writer.write("\n")
        except pyodbc.Error as e:
            handle_exception_in_file(e, file_writer)
        except Exception as e:
            logger.error(str(e))
            return False
    else:
        logger.info("Currently, Driver not supported for TestAuth.")
    return True

def create_connection_string(result, connection_properties, other_prop):
    for i in range(1,len(result)):
        if result[i].startswith("others"):
            other_prop = result[i].replace("others|-|","")
        else:
            property = result[i].split("|-|")
            connection_properties[property[0]] =  property[1]
    connection_str = 'DRIVER={};SERVER={},{};DATABASE={};UID={};PWD={}'.format(cfg["provider"], connection_properties["serverName"], connection_properties["portNumber"], connection_properties["database"], connection_properties["user"], connection_properties["password"])
    return connection_str + ";" + other_prop