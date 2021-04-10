# Adapted from https://github.com/h3rald/litestore/issues/58
FROM alpine:latest

ARG USER=litestore
ENV HOME /home/$USER

RUN apk add --no-cache gcc musl-dev git sudo

# add new user
RUN adduser -D $USER && \
		echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER && \
		chmod 0440 /etc/sudoers.d/$USER

# install nim and nimble (https://github.com/Docker-Hub-frolvlad/docker-alpine-nim/blob/master/Dockerfile)
RUN export NIM_VERSION=1.4.4 && \
    export NIMBLE_VERSION=0.12.0 && \
    \
    apk add --no-cache libcrypto1.1 libssl1.1 && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates git && \
    mkdir -p "/opt" && \
    \
    cd "/opt" && \
    wget "https://github.com/nim-lang/Nim/archive/v$NIM_VERSION.tar.gz" -O - | tar xz && \
    mv "./Nim-$NIM_VERSION" "./Nim" && \
    cd "./Nim" && \
    wget "https://github.com/nim-lang/csources/archive/master.tar.gz" -O - | tar xz && \
    mv "./csources-master" "./csources" && \
    cd "./csources" && \
    sh build.sh && \
    cd .. && \
    ./bin/nim c koch && \
    ./koch boot -d:release && \
    chmod +x "/opt/Nim/bin/nim" && \
    ln -s "/opt/Nim/bin/nim" "/usr/local/bin/nim" && \
    rm -r "./csources" "./tests" && \
    \
    cd "/opt" && \
    wget "https://github.com/nim-lang/nimble/archive/v$NIMBLE_VERSION.tar.gz" -O - | tar xz && \
    cd "./nimble-$NIMBLE_VERSION" && \
    nim compile --run "src/nimble" build --accept && \
    rm -rf /tmp/* && \
    chmod +x nimble && \
    mv nimble "/usr/local/bin/" && \
    rm -rf "/opt/nimble-$NIMBLE_VERSION" && \
    \
    apk del .build-dependencies 

# install litestore and dependencies
RUN nimble install --verbose -y nimgen && \
    ln -s $HOME/.nimble/bin/nimgen /usr/bin/nimgen && \
   nimble install --verbose -y c2nim && \
   ln -s $HOME/.nimble/bin/c2nim /usr/bin/c2nim && \
  nimble install --verbose -y litestore && \
  ln -s $HOME/.nimble/bin/litestore /usr/bin/litestore
USER $USER
WORKDIR $HOME
ENTRYPOINT ["litestore"]

