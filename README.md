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
that the config always include the correct port that your server should be
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

I haven't yet added a script to compile this binary. You can use [this
binary](https://github.com/ryandotsmith/nginx-buildpack/blob/master/bin/nginx),
or compile your own with [this script](https://github.com/ryandotsmith/nginx-buildpack/blob/master/scripts/build_nginx.sh).

Create a Procfile to start the nginx server.

    echo "web: bin/start_nginx" > Procfile

Now, simply commit your changes & push to heroku.

    echo "Hello, World" > www/index.html
    git add .
    git commit -m "Set up static site"
    git push heroku master

View your website with:

    heroku open

## TODO:

* Add a script to build binaries.
