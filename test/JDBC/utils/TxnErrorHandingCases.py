import random
import sys


prefix = 'ErrorHandling'
goTerm = 'GO\n'

blockCount = 0
tryList = []
procList = []
procOpen = []
txnCnt = 0
spList = []

testNum = 1
testDict = {}
opNum = 0
batchDone = False

class Operation:
    def __init__(self):
        global opNum
        self.inc = 0
        self.active = False;
        self.opNum = opNum
        self.batch = False
        opNum = opNum + 1

    def getSQL(self):
        pass

    def getOpNum(self):
        return str(self.opNum)

    def appendTerm(self, sql):
        sql += ';\n'
        if not self.batch:
            sql += goTerm
        return sql

    def appendOnlyGo(self, sql):
        if not self.batch:
            sql += 'GO\n'
        return sql

    def include(self):
        self.inc = self.inc + 1

    def exclude(self):
        self.inc = self.inc - 1

    def isInclude(self):
        return (self.inc > 0)

    def push(self, stmts):
        if stmtDict.get("ERROR_COMMAND").isActive():
            return False
        if blockCount > 0:
            self.batch = True
        self.active = True
        return True

    def pop(self):
        self.active = False
        self.batch = False

    def isActive(self):
        return self.active

    def validStmt(self):
        global stmtDict, procList
        validStmt = stmtDict.get("ERROR_COMMAND").isActive()
        if not validStmt:
            for proc in procList:
                if stmtDict.get("EXEC_PROC" + str(proc)).isActive():
                    validStmt = True
                    break
        return validStmt


class XactAbort(Operation):
    def __init__(self):
        super().__init__()
        self.params = ['ON', 'OFF']
        self.idx = 0

    def getSQL(self):
        res = []
        sql = 'set xact_abort ' + self.params[self.idx]
        self.idx = (self.idx + 1)%2
        res.append(self.appendTerm(sql))
        return res

class ImplTxns(Operation):
    def __init__(self):
        super().__init__()
        self.params = ['ON', 'OFF']

    def getSQL(self):
        res = []
        sql = 'set implicit_transactions ' + self.params[random.randint(0,1)]
        res.append(self.appendTerm(sql))
        return res

class BeginTxn(Operation):

    def getSQL(self):
        res = [self.appendTerm('begin transaction')]
        return res

    def push(self, stmts):
        global txnCnt
        if stmtDict.get("ERROR_COMMAND").isActive():
            return False
        txnCnt = txnCnt + 1
        if blockCount > 0:
            self.batch = True
        return True

    def pop(self):
        global txnCnt
        txnCnt = txnCnt - 1
        self.batch = False

class CommitTxn(Operation):

    def getSQL(self):
        res = [self.appendTerm('commit transaction')]
        return res

    def push(self, stmts):
        global txnCnt
        if txnCnt == 0:
            return False;
        if not self.validStmt():
            return False
        if blockCount > 0:
            self.batch = True
        txnCnt = txnCnt - 1
        return True

    def pop(self):
        global txnCnt
        txnCnt = txnCnt + 1
        self.batch = False

class RollbackTxn(Operation):
    def __init__(self):
        super().__init__()
        self.oldTxnCnt = 0


    def getSQL(self):
        res = [self.appendTerm('rollback transaction')]
        return res

    def push(self, stmts):
        global txnCnt
        if txnCnt == 0:
            return False;
        if not self.validStmt():
            return False
        if blockCount > 0:
            self.batch = True
        self.oldTxnCnt = txnCnt
        txnCnt = 0;
        return True

    def pop(self):
        global txnCnt
        txnCnt = self.oldTxnCnt;
        self.batch = False

class SaveTxn(Operation):
    def __init__(self):
        super().__init__()
        self.params = [prefix + 'sp']

    def getSQL(self):
        res = [self.appendTerm('save transaction ' + self.params[0])]
        return res

    def push(self, stmts):
        global spList
        if txnCnt == 0:
            return False;
        if stmtDict.get("ERROR_COMMAND").isActive():
            return False
        spList.append(self.params[0])
        if blockCount > 0:
            self.batch = True
        return True

    def pop(self):
        global spList
        spList.pop()
        self.batch = False

class RollbackSave(Operation):
    def __init__(self):
        super().__init__()
        self.params = [prefix + 'sp']

    def getSQL(self):
        res = [self.appendTerm('rollback transaction ' + self.params[0])]
        return res

    def push(self, stmts):
        global spList
        if len(spList) == 0:
            return False
        if not self.validStmt():
            return False
        spList.pop()
        if blockCount > 0:
            self.batch = True
        return True

    def pop(self):
        global spList
        spList.append(self.params[0])
        self.batch = False

class Try(Operation):
    def __init__(self, num):
        super().__init__()
        self.num = num;

    def getSQL(self):
        res = ['begin try\n']
        return res;

    def push(self, stmts):
        global blockCount, tryList
        if stmtDict.get("ERROR_COMMAND").isActive():
            return False
        if self.num > len(tryList) + 1:
            return False
        blockCount += 1
        tryList.append(self.num)
        self.batch = True
        return True

    def pop(self):
        global blockCount, tryList
        blockCount -= 1
        tryList.remove(self.num)
        self.batch = False

class Catch(Operation):
    def __init__(self, num):
        super().__init__()
        self.num = num;

    def getSQL(self):
        sql = 'end try\nbegin catch\n\tselect xact_state();\nend catch\n'
        sql = self.appendOnlyGo(sql)
        res = [sql]
        return res;

    def push(self, stmts):
        global blockCount, tryList
        if len(tryList) == 0 or self.num != tryList[-1]:
            return False
        if not self.validStmt():
            return False

        blockCount -= 1
        tryList.remove(self.num)
        if blockCount > 0:
            self.batch = True
        return True

    def pop(self):
        global blockCount, tryList
        blockCount += 1
        tryList.append(self.num)
        self.batch = False


class BeginProc(Operation):
    def __init__(self, num):
        super().__init__()
        self.num = num;

    def getSQL(self):
        res = ['create procedure ' + prefix + str(self.num) + ' as\nbegin\n']
        return res

    def push(self, stmts):
        global blockCount, procOpen
        if blockCount > 0 or len(procOpen) > 0:
            return False
        if self.num > len(procList) + 1:
            return False

        if len(procList) == 0 and stmtDict.get("ERROR_COMMAND").isActive():
            return False

        validStmt = not stmtDict.get("ERROR_COMMAND").isActive()
        for proc in procList:
            if not stmtDict.get("EXEC_PROC" + str(proc)).isActive():
                validStmt = True
                break
        if not validStmt:
            return False

        blockCount += 1
        procOpen.append(self.num)
        self.batch = True
        return True

    def pop(self):
        global blockCount, procOpen
        blockCount -= 1
        procOpen.pop()
        self.batch = False


class EndProc(Operation):
    def __init__(self, num):
        super().__init__()
        self.num = num;

    def getSQL(self):
        res = [self.appendOnlyGo('end\n')]
        return res

    def push(self, stmts):
        global blockCount, procOpen
        if self.num not in procOpen or len(tryList) > 0:
            return False

        stmtValid = False
        for stmt in reversed(stmts):
            if stmt == stmtDict.get("BEGIN_PROC" + str(self.num)):
                break;
            if stmt == stmtDict.get("ERROR_COMMAND"):
                stmtValid = True
                break
            for proc in procList:
                if stmt == stmtDict.get("EXEC_PROC" + str(proc)):
                    stmtValid = True
                    break
                if stmtValid:
                    break

        if not stmtValid:
            return False

        procList.append(self.num)
        blockCount -= 1
        procOpen.pop()
        self.batch = False
        return True

    def pop(self):
        global blockCount, procOpen
        blockCount += 1
        procOpen.append(self.num)
        procList.pop()
        self.batch = False


class ExecProc(Operation):
    def __init__(self, num):
        super().__init__()
        self.num = num;

    def getSQL(self):
        sql = self.appendTerm('exec ' + prefix + str(self.num));
        res = [sql]
        return res

    def push(self, stmts):
        if self.num not in procList:
            return False
        if blockCount > 0:
            self.batch = True
        self.active = True
        return True

class AtAtTranCount(Operation):
    def getSQL(self):
        res = [self.appendTerm('select @@trancount')]
        return res

class PrintError(Operation):
    def __init__(self, comment):
        super().__init__()
        self.done = False
        self.comment = comment

    def getSQL(self):
        self.done = True
        msg = ''
        if self.comment:
            msg += "if @@error > 0 print '" + self.comment + "'"
        elif batchDone:
            msg += "declare @err int = @@error; if (@err > 0 and @@trancount > 0) print 'BATCH ONLY TERMINATING' else if @err > 0 print 'BATCH TERMINATING'"
        else:
            msg +=  "if @@error > 0 print 'STATEMENT TERMINATING ERROR'"
        res = [msg + ";\n"]
        return res

class BatchStart(Operation):
    def getSQL(self):
        global batchDone
        batchDone = False
        return ['']

class BatchEnd(Operation):
    def getSQL(self):
        global batchDone
        batchDone = True
        return ['']

class ErrorCommand(Operation):
    def __init__(self):
        super().__init__()

    def getSQL(self):
        res = [self.appendOnlyGo(commandQuery)]
        return res


stmtDict = {
            "XACT_ABORT": XactAbort(),
            "BEGIN_TXN": BeginTxn(),
            "COMMIT_TXN": CommitTxn(),
            "ROLLBACK_TXN": RollbackTxn(),
            "SAVE_TXN": SaveTxn(),
            "ROLLBACK_SAVE": RollbackSave(),
            "IMPL_TXNS": ImplTxns(),
            "TRY1": Try(1),
            "TRY2": Try(2),
            "CATCH2": Catch(2),
            "CATCH1": Catch(1),
            "BEGIN_PROC1": BeginProc(1),
            "EXEC_PROC2": ExecProc(2),
            "END_PROC1": EndProc(1),
            "BEGIN_PROC2": BeginProc(2),
            "END_PROC2": EndProc(2),
            "EXEC_PROC1": ExecProc(1),
            "ERROR_COMMAND": ErrorCommand()
            }

def writeStmts(testFile, stmt):
    sqls = stmt.getSQL()
    for sql in sqls:
        testFile.write(sql+"\n")

def genBatch(testFile, stmtList, errCmd):
    global testNum
    for i in range(0, len(stmtList) + 1):
        testFile.write('# Executing test ' + prefix + str(testNum) + '\n')
        testFile.write(setupQuery+"\n")
        j = 0
        for stmt in stmtList:
            if (i == j):
                writeStmts(testFile, errCmd)
            writeStmts(testFile, stmt)
            j += 1

        if (i == j):
            writeStmts(testFile, errCmd)

        testFile.write('if @@trancount > 0 rollback transaction\n')
        testFile.write('set xact_abort OFF\n')
        testFile.write('set implicit_transactions OFF\n')
        testFile.write(celanupQuery)
        testFile.write('\n\n\n')
        testNum += 1

def genBatch(testFile, stmtList):
    testFile.write('# Executing test ' + prefix + str(testNum) + '\n')
    testFile.write(setupQuery+"\n")
    for stmt in stmtList:
        writeStmts(testFile, stmt)

    testFile.write('if @@trancount > 0 rollback transaction;\n')
    for proc in procList:
        testFile.write('drop procedure ' + prefix + str(proc) + ';\n')
    testFile.write('set xact_abort OFF;\n')
    testFile.write('set implicit_transactions OFF;\n')
    testFile.write(celanupQuery)
    testFile.write('\n\n\n')

def genBasicCases(testFile):
    global testNum, procList
    atAtTranCount = AtAtTranCount();
    errorCommand = ErrorCommand();
    try1 = Try(1);
    try2 = Try(2);
    catch1 = Catch(1);
    catch2 = Catch(2);
    beginProc1 = BeginProc(1);
    beginProc2 = BeginProc(2);
    endProc1 = EndProc(1);
    endProc2 = EndProc(2);
    execProc1 = ExecProc(1);
    execProc2 = ExecProc(2);
    xactAbort = XactAbort();
    beginTxn = BeginTxn();
    commitTxn = CommitTxn();
    printError = PrintError(None);
    printComplError = PrintError("CURRENT BATCH TERMINATING ERROR");

    errorCommand.batch = True
    atAtTranCount.batch = True
    beginTxn.batch = True
    commitTxn.batch = True
    execProc1.batch = True
    catch1.batch = True
    """
    testNum = 10000000
    genBatch(testFile, [BatchStart(), beginTxn, errorCommand,
        printError, atAtTranCount,
        commitTxn, BatchEnd(), printError])
    testNum = 20000000
    genBatch(testFile, [try1, beginTxn, try2, errorCommand, atAtTranCount, catch1, catch2])
    """
    testNum = 10000000
    procList = [1, 2]
    genBatch(testFile, [BatchStart(), beginProc1, errorCommand,
        printError, atAtTranCount,
        endProc1, beginProc2, execProc1, printComplError, endProc2,
        beginTxn, execProc2, BatchEnd(), printError])
    """
    testNum = 40000000
    procList = [1, 2]
    genBatch(testFile, [xactAbort, beginProc1, try1, errorCommand,
        atAtTranCount, catch1, endProc1, beginProc2, execProc1,
        endProc2, beginTxn, execProc2])
    procList.clear()
    testNum = 1
    """

def swap(stmtList, i, j):
    val = stmtList[i]
    stmtList[i] = stmtList[j]
    stmtList[j] = val

def genValidCases(testFile, stmtDict, stmtList, curStmtList, idx):
    global blockCount, testDict, procList, testNum
    if testNum > testEnd:
        return
    procDone = True
    for proc in procList:
        if not stmtDict.get("EXEC_PROC" + str(proc)).isActive():
            procDone = False
            break

    if procDone and stmtDict.get("ERROR_COMMAND").isActive() and blockCount == 0:
        seq = ''
        for stmt in curStmtList:
            seq = seq + stmt.getOpNum()
        if not testDict.get(seq, False):
            if testNum < testStart:
                testNum += 1
                return
            testDict[seq] = True
            genBatch(testFile, curStmtList)
            testNum += 1
        return

    if (len(stmtList) == idx):
        return

    if not stmtList[idx].isInclude():
        genValidCases(testFile, stmtDict, stmtList, curStmtList, idx + 1)

    stmtList[idx].include()
    N = len(stmtList)
    for i in range(idx, N):
        if not stmtList[i].push(curStmtList):
            continue
        curStmtList.append(stmtList[i])
        swap(stmtList, idx, i)
        genValidCases(testFile, stmtDict, stmtList, curStmtList, idx + 1)
        swap(stmtList, idx, i)
        curStmtList.pop()
        stmtList[i].pop()
    stmtList[idx].exclude()

assert len(sys.argv) == 7, "Please provide setup, command and cleanup files together with test range as well as output file"

setupQuery = open(sys.argv[1], "r").read()
commandQuery = open(sys.argv[2], "r").read()
celanupQuery = open(sys.argv[3], "r").read()
testStart = int(sys.argv[4])
testEnd = int(sys.argv[5])

testFile = open(sys.argv[6], "w", buffering=1)
genBasicCases(testFile)
genValidCases(testFile, stmtDict, list(stmtDict.values()), [], 0)
testFile.close()
