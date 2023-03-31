import logging
from file_handler import file_handler
import pytest
from utils.base import add_files, ignored_files
from utils.config import config_dict as cfg
import os
from datetime import datetime
from pathlib import Path

def get_files():
    lst = add_files()
    for item in lst:
        yield item

@pytest.fixture(scope = "session")
def my_setup():
    try:
        log_folder_name = datetime.now().strftime('log_%H_%M_%d_%m_%Y')
        path = Path.cwd().joinpath("logs", log_folder_name)
        Path.mkdir(path, parents = True, exist_ok = True)
        
    except:
        pass
    
    yield log_folder_name

# function to parametrize the input files   
@pytest.fixture(params = get_files())
def fx1(request):
    return request.param

#main test fuctions
def test_main(fx1, my_setup):

    # skip tests specified by config
    if os.path.splitext(fx1)[1] == '.spec' and cfg['runIsolationTests']=='false':
        pytest.skip("Isolation Tests are not allowed - runIsolationTests config param is false")
    if fx1.name in ignored_files:
        pytest.skip("Ignored test file - Modify ignoredTestName to run this step")
    if fx1.name.split(".")[0][:4] == 'ddl_' and cfg['ddlExport'] == 'false':
        pytest.skip("DDL Export test not allowed")

    logfname = my_setup
    
    #console logger
    lgstr = logging.getLogger("Summary-Logger").getChild(fx1.name + "_console")
    sh = logging.StreamHandler()
    lgstr.addHandler(sh)
    lgstr.setLevel(logging.DEBUG)

    #file logger
    s_log = Path.cwd().joinpath("logs", logfname, "summary.log")
    lg = logging.getLogger("Summary-Logger").getChild(fx1.name)
    fh = logging.FileHandler(filename = s_log, mode = "a")
    formatter = logging.Formatter('%(message)s')
    fh.setFormatter(formatter)
    lg.addHandler(fh)
    lg.setLevel(logging.DEBUG)

    passed,failed = file_handler(fx1, logfname)

    output_fmt_str="\n{0:30s}{1:10s} passed={2:3d} failed={3:3d}"

    try:
        assert passed+failed == passed
        lg.info(output_fmt_str.format(os.path.basename(fx1), "PASSED", passed, failed))
        lgstr.info(output_fmt_str.format(os.path.basename(fx1), "PASSED", passed, failed))
        
    except AssertionError as e: 
        lg.error(output_fmt_str.format(os.path.basename(fx1), "FAILED", passed, failed))
        lgstr.error(output_fmt_str.format(os.path.basename(fx1), "FAILED", passed, failed))


    lgstr.removeHandler(sh)
    lg.removeHandler(fh)
    fh.close()
    sh.close()
    
    assert passed+failed == passed


