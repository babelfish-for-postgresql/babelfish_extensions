import pyodbc
import threading
import time
from enum import Flag, auto

from utils.config import config_dict as cfg
from compare_results import process_multiple_resultsets, handle_exception_in_file

self = None


class STEP_FLAG(Flag):
    RETRY = auto()
    NONBLOCK = auto()


class Session():
    def __init__(self, name, teardownsql=None, autocommit=True):
        self.name = name
        self.setupsqls = []
        self.teardownsql = teardownsql
        self.steps = []
        self.conn = None
        self.autocommit = autocommit
        self.activeStep = None
        self.parentTestSpec = None

    def getConnAndSetup(self):
        self.conn = Conn(self, autocommit=self.autocommit)
        if not self.setupsqls:
            return
        for setup in self.setupsqls:
            self.sessionBatchExecute(setup)

    def teardownAndCloseConn(self):
        if self.teardownsql is not None:
            self.sessionBatchExecute(self.teardownsql)
        if self.conn is not None:
            self.conn.closeCnxnAndCur()

    def sessionBatchExecute(self, batch):
        if self.conn is None:
            self.parentTestSpec.logger("Error : Connection doesn't exist")
        self.conn.executeBatch(batch)

    def __repr__(self) -> str:
        return '{' + str(self.name) + ':' + str(','.join(self.setupsqls)) + ':' + str(self.teardownsql) + ':' + str(self.steps) + '}'


class MasterSession(Session):
    def __init__(self, name='master', teardownsql=None, autocommit=True):
        super().__init__(name, teardownsql, autocommit)
        self.allPidList = []

    def checkForLock(self, blocked_pid):
        self.conn.cur.execute(
            "SELECT pg_catalog.pg_isolation_test_session_is_blocked(?,'{" + ",".join(self.allPidList) + "}');", str(blocked_pid))
        (res,) = self.conn.cur.fetchone()
        if res == 1:
            return True
        return False

    def cancelQuery(self, pid):
        self.conn.cur.execute("SELECT pg_cancel_backend(?);", pid)

    def terminateSession(self, pid):
        self.conn.cur.execute("SELECT pg_terminate_backend(?);", pid)


class Step():
    def __init__(self, name, sql, session):
        self.name = name
        self.sql = sql
        self.session = session

    def __repr__(self) -> str:
        return '{' + str(self.name) + ':' + str(self.sql) + ':' + str(self.session.name) + '}'


class Pstep():
    def __init__(self, step=None, blocker=None, parentPermutation=None):
        self.step = step
        self.blocker = blocker
        self.parentPermutation = parentPermutation

    def __repr__(self) -> str:
        return self.step.name + str(self.blocker)

    def hasBlocker(self):
        for otherStep in self.blocker.otherStepBlocker:
            if (otherStep.session.activeStep is not None) and (otherStep.session.activeStep.step is otherStep):
                return True
        return False

    def tryCompleteStep(self, flag):
        step = self.step
        conn = step.session.conn
        testSpec = step.session.parentTestSpec
        permutation = self.parentPermutation
        logger = testSpec.logger
        fileWriter = testSpec.fileWriter
        masterSession = permutation.masterSession
        waiting = permutation.waiting

        canceled = False

        if not(flag & STEP_FLAG.RETRY):
            if self.blocker.isFirstTryBlocker is True:
                fileWriter.write("step {} <waiting ...>\n".format(step.name))
                return True

        start_time = time.time()
        while(conn.isBusy()):
            # Two options : it will be executing or blocked
            if(flag & STEP_FLAG.NONBLOCK):
                # Perform lock query
                waiting_flag = masterSession.checkForLock(conn.backendPid)
                if(waiting_flag):
                    if(conn.isBusy() is False):
                        break
                    if not(flag & STEP_FLAG.RETRY):
                        fileWriter.write("step {}: {} <waiting ...>\n".format(step.name, step.sql))
                    return True
                # else not waiting
            # if not waiting for lock then it must be some weird query
            # so just cancel that query if it times out
            taken_time = time.time() - start_time
            if(taken_time > int(cfg['stepTimeLimit']) and canceled is False):
                masterSession.cancelQuery(step.session.conn.backendPid)
                logger.info("canceling step {} after {} seconds\n".format(
                    step.name, taken_time))
                canceled = True
            if(taken_time > 2 * int(cfg['stepTimeLimit'])):
                # Raise Exp(if needed) for denoting test failure
                # for now exit() works
                logger.error("step exceeded stepTimeLimit")
                exit(1)

        # step is done but if there is some blocker we shouldn't show it as completed
        # we've to wait for blockers
        if (self.hasBlocker()):
            if not(flag & STEP_FLAG.RETRY):
                fileWriter.write("step {}: {} <waiting ...>\n".format(step.name, step.sql))
            return True

        # otherwise go ahead and complete it
        if(flag & STEP_FLAG.RETRY):
            fileWriter.write("step {}: <... completed>\n".format(step.name))
        else:
            fileWriter.write("step {}: {}\n".format(step.name, step.sql))

        # print result ,err messages
        conn.printResult()
        step.session.activeStep = None
        for x in waiting:
            if x is self:
                waiting.remove(x)
                break
        # waiting.remove(waiting.index(oldstep))
        return False


class Blocker():
    def __init__(self):
        self.isFirstTryBlocker = False
        self.otherStepBlocker = []

    def __repr__(self) -> str:
        res = ''
        if self.isFirstTryBlocker is True:
            res += '*'
        for otherStep in self.otherStepBlocker:
            if res is not '':
                res += ','
            res += otherStep.name
        if res is not '':
            res = '(' + res + ')'
        return res


class Permutation():
    def __init__(self):
        self.psteps = []
        self.parentTestSpec = None
        self.waiting = []
        self.masterSession = None

    def __repr__(self) -> str:
        res = " ".join([str(x.step.name) for x in self.psteps])
        return '{ ' + res + ' }'

    def runAllPermutation(self):
        totalSteps = 0
        for sess in self.parentTestSpec.sessions:
            totalSteps += len(sess.steps)
        usedSteps = [0 for i in range(totalSteps)]
        self.psteps = [Pstep(blocker=Blocker(), parentPermutation=self) for i in range(totalSteps)]
        self.generatePermutation(usedSteps, 0)

    def generatePermutation(self, usedSteps, currentIndex):
        anyStepAdded = False
        sessions = self.parentTestSpec.sessions
        for i in range(len(sessions)):
            if usedSteps[i] < len(sessions[i].steps):
                self.psteps[currentIndex].step = sessions[i].steps[usedSteps[i]]
                usedSteps[i] += 1
                self.generatePermutation(usedSteps, currentIndex + 1)
                usedSteps[i] -= 1
                anyStepAdded = True
        if not(anyStepAdded):
            self.runPermutation()

    '''
    Run this permutaion
        - Create connections
        - Main setup
        - Per session setup
        - Execute steps
        - Per session teardown
        - Main teardown
        - Close connections
    '''

    def runPermutation(self):
        try:
            self.waiting = []
            testSpec = self.parentTestSpec
            fileWriter = testSpec.fileWriter
            logger = testSpec.logger

            logmsg = "\nstarting permutation : {}\n".format(str(self))
            fileWriter.write(logmsg)
            logger.info(logmsg)

            # Create and Setup Sessions
            masterSession = MasterSession(autocommit=True)
            masterSession.setupsqls = testSpec.setupsqls
            masterSession.teardownsql = testSpec.teardownsql
            masterSession.parentTestSpec = testSpec
            masterSession.getConnAndSetup()
            self.masterSession = masterSession
            for sess in testSpec.sessions:
                sess.parentTestSpec = testSpec
                sess.getConnAndSetup()
                sess.conn.start()
                masterSession.allPidList.append(str(sess.conn.backendPid))

            logger.info("Session setup completed for {}".format(str(self)))

            for pstep in self.psteps:
                '''
                Check whether the session that needs to perform the next step is 
                still blocked on an earlier step.  If so, wait for it to finish. 
                '''
                step = pstep.step
                sess = step.session
                if sess.activeStep is not None:
                    # note start time
                    start_time = time.time()
                    while(sess.activeStep is not None):
                        oldstep = sess.activeStep
                        '''
                        Wait for oldstep.  But even though we don't use
                        STEP_NONBLOCK, it might not complete because of blocker
                        conditions.
                        '''
                        oldstep.tryCompleteStep(STEP_FLAG.RETRY)
                        self.tryCompleteSteps(STEP_FLAG.NONBLOCK | STEP_FLAG.RETRY)
                        if sess.activeStep is not None:
                            taken_time = time.time() - start_time
                            if taken_time > 2 * int(cfg['stepTimeLimit']):
                                logger.error("step {} timed out after {} seconds\n".format(
                                    oldstep.step.name, taken_time))
                                # print active steps of other sessions also (if required)
                                exit(1)
                sess.activeStep = pstep
                sess.conn.executeactiveStep()

                mustwait = pstep.tryCompleteStep(STEP_FLAG.NONBLOCK)
                self.tryCompleteSteps(STEP_FLAG.NONBLOCK | STEP_FLAG.RETRY)
                if mustwait is True:
                    self.waiting.append(pstep)

            self.tryCompleteSteps(STEP_FLAG.RETRY)
            if len(self.waiting) is not 0:
                raise Exception("Failed to complete permutation due to mutually-blocking steps\n")
        except Exception as e:
            raise e
        finally:
            # Teardown at session level
            for sess in testSpec.sessions:
                if sess.conn is not None:
                    sess.conn.stop()
                sess.teardownAndCloseConn()

            # Teardown
            masterSession.teardownAndCloseConn()
            logger.info("Teardown completed for {}".format(str(self)))

    def tryCompleteSteps(self, flags):
        for pstep in self.waiting:
            pstep.tryCompleteStep(flags)


class Conn(threading.Thread):
    def __init__(self, sess=None, autocommit=False):
        threading.Thread.__init__(self)
        self.lock = threading.Event()
        self.stopEvent = threading.Event()
        self.sess = sess
        self.logger = self.sess.parentTestSpec.logger
        self.cnxn = pyodbc.connect('DRIVER={};SERVER={},{};DATABASE={};UID={};PWD={}'.format(
            cfg['provider'],
            cfg['fileGenerator_URL'],
            cfg['fileGenerator_port'],
            cfg['fileGenerator_databaseName'],
            cfg['fileGenerator_user'],
            cfg['fileGenerator_password']),
            autocommit=autocommit)
        self.cur = self.getCursor()
        self.backendPid = self.getBackendPid()

    def getCursor(self):
        return self.cnxn.cursor()

    def getBackendPid(self):
        self.cur.execute("SELECT pg_backend_pid();")
        (res,) = self.cur.fetchone()
        return res

    def executeactiveStep(self):
        self.lock.set()

    def executeBatch(self, batch):
        self.cur.execute(batch)

    def printResult(self):
        process_multiple_resultsets(self.cur, self.sess.parentTestSpec.fileWriter, 0, None)

    def closeCnxnAndCur(self):
        if(self.cur is not None):
            self.cur.close()
        if(self.cnxn is not None):
            self.cnxn.close()

    def isBusy(self):
        return self.lock.is_set()

    def stop(self):
        self.stopEvent.set()

    def run(self):
        while(True):
            if self.stopEvent.is_set():
                break
            if self.lock.is_set():
                try:
                    self.cur.execute(self.sess.activeStep.step.sql)
                except pyodbc.Error as e:
                    handle_exception_in_file(e, self.sess.parentTestSpec.fileWriter)
                    self.cur.nextset()
                finally:
                    self.lock.clear()


class TestSpec():
    def __init__(self):
        self.setupsqls = []
        self.teardownsql = None
        self.sessions = []
        self.permutations = []
        self.fileWriter = None
        self.logger = None

    def __repr__(self) -> str:
        return '{' + str(self.setupsqls) + ':' + str(self.teardownsql) + ':' + str(self.sessions) + ':' + str(self.permutations) + '}'

    def initTestRun(self):
        if self.permutations:
            for permutation in self.permutations:
                permutation.runPermutation()
        else:
            permutation = Permutation()
            permutation.parentTestSpec = self
            permutation.runAllPermutation()
