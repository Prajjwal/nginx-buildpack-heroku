#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

# This is a modified version of the following:
# https://github.com/ryandotsmith/nginx-buildpack/blob/master/scripts/build_nginx.sh
#
# Changes:
#
# * This version allows you to optionally pass in the NGINX_VERSION & PCRE_VERSION
#   if you wish to build a custom binary.
# * The HEADERS_MORE_VERSION module has also been removed.
# * This version replaces the python server with a ruby one.
# * This also creates an archive of the compiled binary to make downloading
#   easier. It is at /tmp/heroku-nginx.tar.gz
#
# Check the "Building your binary" section in the README for more information.

NGINX_VERSION=1.13.7
PCRE_VERSION=8.41

# Set custom NGINX_VERSION & PCRE_VERSION if passed in as parameters.
[ -z $1 ] || NGINX_VERSION=$1
[ -z $2 ] || PCRE_VERSION=$2

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2/download

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

echo "Downloading $pcre_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvj )

# Compile to /tmp/nginx
(
	cd nginx-${NGINX_VERSION}
	./configure \
		--with-pcre=pcre-${PCRE_VERSION} \
		--prefix=/tmp/nginx
	make install
)

# Start serving the contents of /tmp with the nginx binary itself, to make sure
# it works.
erb ~/conf/nginx.conf.erb > /tmp/nginx/conf/nginx.conf
mkdir -p /tmp/logs
touch /tmp/logs/access.log /tmp/logs/error.log
/tmp/nginx/sbin/nginx &

# Create compressed tarballs to make downloading easy.
cd /tmp
echo "Built for use on Heroku with the nginx buildpack." > README.txt
echo "https://github.com/Prajjwal/nginx-buildpack-heroku.git" >> README.txt
tar cfa heroku-nginx-full.tar.gz nginx/ README.txt
cd /tmp/nginx/sbin/
tar cfa /tmp/heroku-nginx.tar.gz nginx ../conf/mime.types ../../README.txt

# Make sure the script does not exit, causing the app to crash before you get a
# chance to download your heroku-nginx.tar.gz.
while true; do
	sleep 1
done
