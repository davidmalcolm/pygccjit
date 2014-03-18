
import unittest

class TestLoader(unittest.TestLoader):
    def loadTestsFromName(self, name, module=None):
        if '.' in name:
            return super().loadTestsFromName(name, module)
        return self.discover(name)
