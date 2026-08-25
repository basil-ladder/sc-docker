import unittest
from .files_test import TestFindFiles
from .meta_test import TestBotMetaParsing
from .test_runtime_capabilities import TestRuntimeCapabilities
from .cli_test import TestConfiguredDataDirectories

def suite():

    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(TestFindFiles))
    suite.addTest(unittest.makeSuite(TestBotMetaParsing))
    suite.addTest(unittest.makeSuite(TestRuntimeCapabilities))
    suite.addTest(unittest.makeSuite(TestConfiguredDataDirectories))

    return suite
