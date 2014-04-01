# Nginx Buildpack

Heroku buildpack for serving static sites with nginx.

## Usage:

Initialize your static site as a git repository.

    git init somesite

Create directories for nginx configuration & your site.

    cd somesite
    mkdir conf
    mkdir www

This build pack expects an nginx.conf.erb to be present at conf/. It must

You must define all listen directives as listen `<%= ENV['PORT'] %>`. This ensures
that the config always includes the correct port that your server should be
listening on.

Your config should also include `daemon off;`.

A sample nginx.conf.erb is as follows:

    worker_processes 1;
    daemon off;

    events {
      worker_connections 1024;
    }


    http {
      include mime.types;
      default_type application/octet-stream;

      sendfile on;
      keepalive_timeout 65;

      server {
        listen <%= ENV['PORT'] %>;
        server_name localhost;

        error_page 404 /404.html;

        location / {
          root www;
          expires 180s;
          add_header Vary Accept-Encoding;
        }
      }

    }

The above will serve your site present at www/.

Next, create a heroku app with:

    heroku create --buildpack https://github.com/Prajjwal/nginx-buildpack-heroku.git

The buildpack expects a url to your compiled & gzipped binary in a config var
called `$NGINX_BINARY_URL`. The build will fail if this isn't present. Set this with:

    heroku config:set NGINX_BINARY_URL=http://example.com/nginx.tar.gz

You can get away with using your Dropbox public folder to host this binary. I
would recommend Amazon S3 for anything critical.

You can use [this binary](https://github.com/ryandotsmith/nginx-buildpack/blob/master/bin/nginx).
See the "Building Your Binary" section below for instructions on how to build
your own binary.

Create a Procfile to start the nginx server.

    echo "web: bin/start_nginx" > Procfile

Now, simply commit your changes & push to heroku.

    echo "Hello, World" > www/index.html
    git add .
    git commit -m "Set up static site"
    git push heroku master

View your website with:

    heroku open

## Building Your Binary

This buildpack is in itself a heroku app that automatically compiles nginx and
starts a little server that you can use to download it. You don't need to build
your own binary unless you don't trust mine or need a different version of pcre
or nginx. Here's how:

    git clone https://github.com/Prajjwal/nginx-buildpack-heroku.git

    cd nginx-buildpack-heroku

    heroku create

    git push heroku master

    heroku open

This should open a web page that serves the `/tmp` dir of your heroku instance.

Nginx has been installed to `/tmp/nginx`. There are also two gzipped tarballs.
`heroku-nginx.tar.gz` is the one you should probably download. It contains the
binary at the root, and should work out of the box with this buildpack.

`heroku-nginx-full.tar.gz` contains the entire nginx install at `/tmp/nginx/`.
This will not work out of the box with this buildpack because the nginx binary
is in the `sbin/` dir within the archive, and not at the root where it is
expected to be.

## Hacking

The build script also takes two optional parameters for the nginx & pcre versions.
If you want a version of nginx or pcre other than the one that is hard coded
into the script, simply fork this repository and change your Procfile to read:

    web: scripts/compile.sh <nginx_version> <pcre_version>

## Credits

This build pack is basically stolen from [here](https://github.com/essh/heroku-buildpack-nginx),
because the author stopped actively maintaining it. This pack is aims to be
slightly better documented & to read the nginx binary url from a config var.

The script to build the nginx binary was forked from
[here](https://github.com/ryandotsmith/nginx-buildpack/blob/master/scripts/build_nginx.sh).
