import unittest

from scbw.docker_utils import (
    cuda_device_requests,
    docker_image_for_player,
    startup_grace_frames,
)
from scbw.player import BotPlayer, HumanPlayer


def bot_player(**metadata):
    player = BotPlayer.__new__(BotPlayer)
    player.meta = BotPlayer.parse_meta(dict({
        "name": "Test Bot",
        "race": "Random",
        "botType": "AI_MODULE",
    }, **metadata))
    return player


class TestRuntimeCapabilities(unittest.TestCase):
    def test_existing_bots_retain_default_image_without_gpu(self):
        player = bot_player()

        self.assertEqual(
            "starcraft:game",
            docker_image_for_player(
                player, "starcraft:game", "starcraft:game-wow64"
            ),
        )
        self.assertIsNone(cuda_device_requests(player))
        self.assertEqual(0, startup_grace_frames([player]))

    def test_win64_bot_uses_wow64_image(self):
        player = bot_player(wineArchitecture="win64")

        self.assertEqual(
            "starcraft:game-wow64",
            docker_image_for_player(
                player, "starcraft:game", "starcraft:game-wow64"
            ),
        )
        self.assertIsNone(cuda_device_requests(player))

    def test_cuda_bot_requests_all_gpus(self):
        player = bot_player(wineArchitecture="win64", requiresCuda=True)

        request = cuda_device_requests(player)[0]
        self.assertEqual(-1, request["Count"])
        self.assertEqual([["gpu"]], request["Capabilities"])

    def test_largest_startup_grace_applies_to_the_game(self):
        players = [
            bot_player(startupGraceFrames=1440),
            bot_player(wineArchitecture="win64", startupGraceFrames=86400),
        ]

        self.assertEqual(86400, startup_grace_frames(players))

    def test_human_player_retains_default_runtime(self):
        player = HumanPlayer()

        self.assertEqual(
            "custom:game",
            docker_image_for_player(
                player, "custom:game", "custom:game-wow64"
            ),
        )
        self.assertIsNone(cuda_device_requests(player))


if __name__ == '__main__':
    unittest.main()
