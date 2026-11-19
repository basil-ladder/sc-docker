$ErrorActionPreference = "Stop"
docker build -f dockerfiles/wine.dockerfile  -t starcraft:wine   .
if (-not $?) {throw "Failed to build starcraft:wine image"}
docker build -f dockerfiles/bwapi.dockerfile -t starcraft:bwapi  .
if (-not $?) {throw "Failed to build starcraft:bwapi image"}
docker build -f dockerfiles/play.dockerfile  -t starcraft:play   .
if (-not $?) {throw "Failed to build starcraft:play image"}
docker build -f dockerfiles/java.dockerfile  -t starcraft:java   .
if (-not $?) {throw "Failed to build starcraft:java image. You can verify that you will build with proper version of Java in file dockerfiles/play.dockerfile"}

docker build --build-arg WINE_ARCH=win64 -f dockerfiles/wine.dockerfile -t starcraft:wine-wow64 .
if (-not $?) {throw "Failed to build starcraft:wine-wow64 image"}
docker build --build-arg BASE_IMAGE=starcraft:wine-wow64 -f dockerfiles/bwapi.dockerfile -t starcraft:bwapi-wow64 .
if (-not $?) {throw "Failed to build starcraft:bwapi-wow64 image"}
docker build --build-arg BASE_IMAGE=starcraft:bwapi-wow64 -f dockerfiles/play.dockerfile -t starcraft:play-wow64 .
if (-not $?) {throw "Failed to build starcraft:play-wow64 image"}
docker build --build-arg BASE_IMAGE=starcraft:play-wow64 -f dockerfiles/java.dockerfile -t starcraft:java-wow64 .
if (-not $?) {throw "Failed to build starcraft:java-wow64 image"}

Push-Location ../scbw/local_docker
if (!(Test-Path starcraft.zip))
{
    Invoke-WebRequest 'http://files.theabyss.ru/sc/starcraft.zip' -OutFile starcraft.zip
}

docker build -f game.dockerfile  -t "starcraft:game" .
if (-not $?) {throw "Failed to build starcraft:game image"}
docker build --build-arg BASE_IMAGE=starcraft:java-wow64 -f game.dockerfile -t "starcraft:game-wow64" .
if (-not $?) {throw "Failed to build starcraft:game-wow64 image"}
Pop-Location
