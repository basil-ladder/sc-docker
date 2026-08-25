import unittest
from argparse import Namespace
from pathlib import Path
from tempfile import TemporaryDirectory

from scbw.cli import missing_data_directories


class TestConfiguredDataDirectories(unittest.TestCase):
    def test_explicit_directories_do_not_require_default_data_root(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            directories = [root / name for name in ("bots", "games", "maps", "bwta", "bwta2")]
            for directory in directories:
                directory.mkdir()
            args = Namespace(
                bot_dir=str(directories[0]),
                game_dir=str(directories[1]),
                map_dir=str(directories[2]),
                bwapi_data_bwta_dir=str(directories[3]),
                bwapi_data_bwta2_dir=str(directories[4]),
            )

            self.assertEqual([], missing_data_directories(args))

    def test_reports_each_missing_configured_directory(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            existing = root / "bots"
            existing.mkdir()
            args = Namespace(
                bot_dir=str(existing),
                game_dir=str(root / "games"),
                map_dir=str(root / "maps"),
                bwapi_data_bwta_dir=str(root / "bwta"),
                bwapi_data_bwta2_dir=str(root / "bwta2"),
            )

            missing = missing_data_directories(args)
            self.assertEqual(4, len(missing))
            self.assertTrue(any(item.startswith("game:") for item in missing))


if __name__ == '__main__':
    unittest.main()
