FROM --platform=linux/amd64 alpine:latest

RUN apk update
RUN apk --no-cache add\
            git \
            libxml2-utils \
            ffmpeg \
            unzip \
            coreutils \
            curl

WORKDIR /app

RUN git clone https://github.com/uru2/rec_radiko_ts && cp rec_radiko_ts/rec_radiko_ts.sh .
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    mv rclone-*-linux-amd64 rclone && \
    cd rclone && \
    cp rclone /usr/bin/ && \
    chmod +x /usr/bin/rclone

COPY ./rclone.conf /root/.config/rclone/rclone.conf
COPY ./secrets/radiko-downloader-ss-sa.json .
COPY ./run.sh .
RUN chmod +x /app/run.sh

CMD ["/app/run.sh"]