import unittest

from pyzoommate.config import _IsValidKeyboardShortcut, _IsValidMeetingID, _IsValidTime


class ConfigValidationTests(unittest.TestCase):
    def test_meeting_id(self):
        self.assertTrue(_IsValidMeetingID("123456789"))
        self.assertTrue(_IsValidMeetingID("12345678901"))
        self.assertFalse(_IsValidMeetingID("123"))

    def test_time(self):
        self.assertTrue(_IsValidTime("9:05"))
        self.assertTrue(_IsValidTime("23:59"))
        self.assertFalse(_IsValidTime("24:00"))

    def test_shortcut(self):
        self.assertTrue(_IsValidKeyboardShortcut("^!z"))
        self.assertTrue(_IsValidKeyboardShortcut(""))
        self.assertFalse(_IsValidKeyboardShortcut("z"))


if __name__ == "__main__":
    unittest.main()
