import unittest
from .files_test import TestFindFiles
from .meta_test import TestBotMetaParsing
from .test_runtime_capabilities import TestRuntimeCapabilities

def suite():

    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(TestFindFiles))
    suite.addTest(unittest.makeSuite(TestBotMetaParsing))
    suite.addTest(unittest.makeSuite(TestRuntimeCapabilities))

    return suite
