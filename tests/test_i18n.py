import unittest

from pyzoommate.i18n import _InitializeTranslations, t


class I18nTests(unittest.TestCase):
    def test_load_english(self):
        _InitializeTranslations("en")
        self.assertIn("ZoomMate", t("CONFIG_TITLE"))


if __name__ == "__main__":
    unittest.main()
