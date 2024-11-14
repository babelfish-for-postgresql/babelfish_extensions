from .isolationTester import Session, Step, Permutation, TestSpec, Pstep, Blocker
from .parser.specParserVisitor import specParserVisitor


# Generated from specParser.g4 by ANTLR 4.13.2
from antlr4 import *
from .parser.specParser import specParser

# This class defines a complete generic visitor for a parse tree produced by specParser.

class specParserVisitorImpl(specParserVisitor):

    def __init__(self):
        self.parentnode_stk = []
        self.steps_defined = {}
        self.testSpec = TestSpec()

    # Visit a parse tree produced by specParser#parse.
    def visitParse(self, ctx:specParser.ParseContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by specParser#self.testSpec.
    def visitTestspec(self, ctx:specParser.TestspecContext):
        self.parentnode_stk.append(self.testSpec)
        for setupsql in ctx.setup():
            self.testSpec.setupsqls.append(trimSQLBLOCK(setupsql.SQLBLOCK().getText()))
        if(ctx.teardown() is not None):
            self.testSpec.teardownsql = trimSQLBLOCK(ctx.teardown().SQLBLOCK().getText())
        for session_child in ctx.session():
            self.visitSession(session_child)
        for permutation_child in ctx.permutation():
            self.visitPermutation(permutation_child)
        self.parentnode_stk.pop()
        return


    # Visit a parse tree produced by specParser#setup.
    def visitSetup(self, ctx:specParser.SetupContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by specParser#teardown.
    def visitTeardown(self, ctx:specParser.TeardownContext):
        return self.visitChildren(ctx)


    # Visit a parse tree produced by specParser#session.
    def visitSession(self, ctx:specParser.SessionContext):
        session = Session(name = ctx.ID().getText())
        session.parentTestSpec = self.parentnode_stk[-1]
        self.parentnode_stk.append(session)
        if(ctx.setup() is not None):
            session.setupsqls.append(trimSQLBLOCK(ctx.setup().SQLBLOCK().getText()))
        if(ctx.teardown() is not None):
            session.teardownsql = trimSQLBLOCK(ctx.teardown().SQLBLOCK().getText())
        for step_ctx in ctx.step():
            self.visitStep(step_ctx)
        self.parentnode_stk.pop()
        self.parentnode_stk[-1].sessions.append(session)
        return

    # Visit a parse tree produced by specParser#pstep.
    def visitPstep(self, ctx:specParser.PstepContext):
        pstep = Pstep(parentPermutation=self.parentnode_stk[-1])
        self.parentnode_stk.append(pstep)
        step_id = ctx.ID().getText()
        step_lookup_res = self.steps_defined.get(step_id)
        if(step_lookup_res is None):
            raise Exception("ParsingError : Undefine step found "+ step_id)
        else :
            pstep.step = step_lookup_res
        if(ctx.blockers() is not None):
            self.visitBlockers(ctx.blockers())
        else:
            pstep.blocker = Blocker()
        self.parentnode_stk.pop()
        self.parentnode_stk[-1].psteps.append(pstep)
        return

    # Visit a parse tree produced by specParser#blockers.
    def visitBlockers(self, ctx:specParser.BlockersContext):
        blocker = Blocker()
        if ctx.AST():
            blocker.isFirstTryBlocker = True
        for otherBlockerStepId in ctx.ID():
            stepLookupRes = self.steps_defined.get(otherBlockerStepId.getText())
            if(stepLookupRes is None):
                raise Exception("ParsingError : Undefine step found "+otherBlockerStepId.getText())
            else:
                blocker.otherStepBlocker.append(stepLookupRes)
        self.parentnode_stk[-1].blocker = blocker
        return


    # Visit a parse tree produced by specParser#permutation.
    def visitPermutation(self, ctx:specParser.PermutationContext):
        permutation = Permutation()
        permutation.parentTestSpec = self.parentnode_stk[-1]
        self.parentnode_stk.append(permutation)
        for pstep in ctx.pstep():
            self.visitPstep(pstep)
        self.parentnode_stk.pop()
        self.parentnode_stk[-1].permutations.append(permutation)
        return


    # Visit a parse tree produced by specParser#step.
    def visitStep(self, ctx:specParser.StepContext):
        old_step_lookup = self.steps_defined.get(ctx.ID().getText())
        if old_step_lookup is not None:
            raise Exception("ParsingError : Steps already defined "+ctx.ID().getText())
        step = Step(ctx.ID().getText(), trimSQLBLOCK(ctx.SQLBLOCK().getText()), self.parentnode_stk[-1])
        self.steps_defined[step.name] = step
        self.parentnode_stk[-1].steps.append(step)
        return


del specParser

def trimSQLBLOCK(text):
    return text[1:-1].strip()
