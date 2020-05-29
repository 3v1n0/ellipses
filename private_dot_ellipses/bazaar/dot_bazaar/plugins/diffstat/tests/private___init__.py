from unittest import TestLoader, TestSuite
from bzrlib.tests import TestUtil

import os

def test_suite():
    loader = TestUtil.TestLoader()
    suite = loader.suiteClass()

    testmod_names = [
        'bzrlib.plugins.diffstat.tests.blackbox.test_diff'
        ]

    suite.addTests(loader.loadTestsFromModuleNames(testmod_names))

    return suite
