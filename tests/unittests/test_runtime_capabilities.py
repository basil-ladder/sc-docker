import unittest
from unittest.mock import patch

from scbw.docker_utils import (
    cuda_device_requests,
    docker_image_for_player,
    startup_grace_frames,
    player_nano_cpu_limits,
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
    def test_cpu_metadata_overrides_only_its_player(self):
        players = [bot_player(cpuLimit=2), bot_player(cpuLimit=1.2), bot_player()]
        self.assertEqual([2000000000, 1200000000, 1700000000],
                         player_nano_cpu_limits(players, 1700000000))
        self.assertEqual([500000000, 0, 3000000000],
                         player_nano_cpu_limits(players, 1700000000, [500000000, 0, 3000000000]))

    def test_invalid_cpu_metadata_and_override_fail(self):
        for value in (True, False, "2", 0, -1, float("nan"), float("inf")):
            with self.subTest(value=value), self.assertRaisesRegex(Exception, "cpuLimit"):
                bot_player(cpuLimit=value)
        for values in ([1], [-1, 2], [True, 2]):
            with self.subTest(values=values), self.assertRaises(Exception):
                player_nano_cpu_limits([bot_player(), bot_player()], None, values)

    def test_cpu_defaults_preserve_uncapped_and_human_players(self):
        self.assertEqual([0, 0], player_nano_cpu_limits([bot_player(cpuLimit=None), HumanPlayer()], None))

    def test_launch_passes_each_cpu_limit_to_docker(self):
        from scbw.docker_utils import launch_game
        players = [bot_player(cpuLimit=2), bot_player(cpuLimit=1.2)]
        params = dict(game_dir="unused", game_name="CPU_TEST", nano_cpus=1700000000,
                      headless=True, player_nano_cpus=[2000000000, 1200000000])
        with patch("scbw.docker_utils.os.path.exists", return_value=False), \
                patch("scbw.docker_utils.launch_image") as launch, \
                patch("scbw.docker_utils.time.sleep"), \
                patch("scbw.docker_utils.running_containers", side_effect=[["p0", "p1"], []]), \
                patch("scbw.docker_utils.docker_client") as client, \
                patch("scbw.docker_utils.remove_game_containers"):
            client.containers.list.return_value = []
            launch_game(players, params, False, False, lambda: None)
        self.assertEqual([2000000000, 1200000000],
                         [call.kwargs["nano_cpus"] for call in launch.call_args_list])
        self.assertTrue(all("player_nano_cpus" not in call.kwargs for call in launch.call_args_list))

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
