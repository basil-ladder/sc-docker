#!/bin/bash

docker image inspect starcraft:game > /dev/null 2>&1
HAS_GAME_IMAGE=$?
docker image inspect starcraft:game-wow64 > /dev/null 2>&1
HAS_WOW64_IMAGE=$?
if [ $HAS_GAME_IMAGE -ne 0 ] || [ $HAS_WOW64_IMAGE -ne 0 ]; then
	docker run -v /var/run/docker.sock:/var/run/docker.sock -e STARCRAFT_UID=$(id -u) scbw /bin/bash -c "cd scbw/docker; ./build_images.sh"
	docker run -v /var/run/docker.sock:/var/run/docker.sock scbw --install
fi

mkdir ~/.scbw 2> /dev/null
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v ~/.scbw:/root/.scbw scbw scbw.play "$@"
