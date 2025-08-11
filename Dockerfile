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
RUN wget https://github.com/glotlabs/gdrive/releases/download/3.9.1/gdrive_linux-x64.tar.gz && \
    tar -xzvf gdrive_linux-x64.tar.gz && \
    rm gdrive_linux-x64.tar.gz && \
    mv gdrive /usr/bin/ && \
    chmod +x /usr/bin/gdrive

COPY ./secrets/gdrive_secret.tar .
COPY ./run.sh .
RUN chmod +x /app/run.sh

CMD ["/app/run.sh"]