docker build . -t us-west1-docker.pkg.dev/takedarut-radiko-downloader/radiko-downloader/radiko-downloader:latest --no-cache
docker push us-west1-docker.pkg.dev/takedarut-radiko-downloader/radiko-downloader/radiko-downloader:latest
gcloud artifacts docker images list us-west1-docker.pkg.dev/takedarut-radiko-downloader/radiko-downloader/radiko-downloader
