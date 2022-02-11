#a wrapper on main test container to enable functionality like multithreading and backtracing error
import pytest
from utils.config import config_dict as cfg

#arguments added to clean the console output to just include test summary
arguments = ["-vs", "--no-header", "--tb=long", "--no-summary"]


#Multiprocessing
if cfg["runInParallel"].lower() == "true":
    arguments.append("-n 4")

#add print to console
arguments.append("-s")

#to remove duplicate arguments from arguments list
arguments=list(set(arguments))

#check if driver is supported by the framework
if cfg["driver"] in ["pyodbc", "pymssql"]:
    arguments.append("test_main.py")
    pytest.main(args = arguments)
else:
    print("\nERROR: Driver not supported by the framework\n")
