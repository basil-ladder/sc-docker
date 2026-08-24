#!/usr/bin/env bash
set -eux

BUILD_ARGS="--build-arg BOT_UID=${BOT_UID:-2001} --build-arg STARCRAFT_UID=${STARCRAFT_UID:-$(id -u)}"

docker build ${BUILD_ARGS} -f dockerfiles/wine.dockerfile  -t starcraft:wine   .
docker build ${BUILD_ARGS} -f dockerfiles/bwapi.dockerfile -t starcraft:bwapi  .
docker build ${BUILD_ARGS} -f dockerfiles/play.dockerfile  -t starcraft:play   .
docker build ${BUILD_ARGS} -f dockerfiles/java.dockerfile  -t starcraft:java   .

docker build ${BUILD_ARGS} --build-arg WINE_ARCH=win64 -f dockerfiles/wine.dockerfile -t starcraft:wine-wow64 .
docker build ${BUILD_ARGS} --build-arg BASE_IMAGE=starcraft:wine-wow64 -f dockerfiles/bwapi.dockerfile -t starcraft:bwapi-wow64 .
docker build ${BUILD_ARGS} --build-arg BASE_IMAGE=starcraft:bwapi-wow64 -f dockerfiles/play.dockerfile -t starcraft:play-wow64 .
docker build ${BUILD_ARGS} --build-arg BASE_IMAGE=starcraft:play-wow64 -f dockerfiles/java.dockerfile -t starcraft:java-wow64 .

pushd ../scbw/local_docker
[ ! -f starcraft.zip ] && curl -SL 'http://files.theabyss.ru/sc/starcraft.zip' -o starcraft.zip
docker build ${BUILD_ARGS} -f game.dockerfile  -t "starcraft:game" .
docker build ${BUILD_ARGS} --build-arg BASE_IMAGE=starcraft:java-wow64 -f game.dockerfile -t "starcraft:game-wow64" .
popd
