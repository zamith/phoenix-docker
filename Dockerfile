# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# @zamith wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return
# ----------------------------------------------------------------------------

FROM zamith/elixir
MAINTAINER Zamith <luis@zamith.pt>

# Important!  Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT 2016-04-23

# Check SHA256 at https://nodejs.org/dist/v5.10.1/SHASUMS256.txt
ENV NODEJS_VERSION=5.10.1 \
    NODEJS_SHA256=c6e278b612b53c240ddf85521403e55abfd8f0201d2f2c7e3d2c21383054aacd \
    NPM_VERSION=3.7.1

RUN info(){ printf '\n--\n%s\n--\n\n' "$*"; } \
 && info "==> Installing dependencies..." \
 && apk update \
 && apk add --virtual build-deps \
    curl make gcc g++ python paxctl \
    musl-dev openssl-dev zlib-dev \
    linux-headers binutils-gold \
 && mkdir -p /root/nodejs \
 && cd /root/nodejs \
 && info "==> Downloading..." \
 && curl -sSL -o node.tar.gz http://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}.tar.gz \
 && echo "$NODEJS_SHA256  node.tar.gz" > node.sha256 \
 && sha256sum -c node.sha256 \
 && info "==> Extracting..." \
 && tar -xzf node.tar.gz \
 && cd node-* \
 && info "==> Configuring..." \
 && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1) \
 && echo "using upto $NPROC threads" \
 && ./configure \
   --prefix=/usr \
   --shared-openssl \
   --shared-zlib \
 && info "==> Building..." \
 && make -j$NPROC -C out mksnapshot \
 && paxctl -c -m out/Release/mksnapshot \
 && make -j$NPROC \
 && info "==> Installing..." \
 && make install \
 && info "==> Finishing..." \
 && apk del build-deps \
 && apk add \
    openssl libgcc libstdc++ \
 && rm -rf /var/cache/apk/* \
 && info "==> Updating NPM..." \
 && npm i -g npm@$NPM_VERSION \
 && info "==> Cleaning up..." \
 && npm cache clean \
 && rm -rf ~/.node-gyp /tmp/* \
 && rm -rf /root/nodejs \
 && echo 'Done! =)'
