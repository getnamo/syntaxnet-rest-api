FROM ljm625/syntaxnet:latest
MAINTAINER Jiaming Li <ljm625@gmail.com>
# Install uWSGI
RUN pip install uwsgi
ENV NGINX_VERSION 1.9.11-1~jessie
RUN apt-get update
RUN apt-get install -y ca-certificates nginx gettext-base
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
# Finished setting up Nginx

# Make NGINX run on the foreground
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
# Copy the modified Nginx conf
COPY nginx.conf /etc/nginx/conf.d/
# Copy the base uWSGI ini file to enable default dynamic uwsgi process number
COPY uwsgi.ini /etc/uwsgi/

# Install Supervisord
RUN apt-get update && apt-get install -y supervisor \
&& rm -rf /var/lib/apt/lists/*
# Custom Supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/conf.d/
COPY ./app /app
RUN pip install -r /app/requirements.txt
RUN mkdir /models
COPY custom_parse.sh /opt/tensorflow/models/syntaxnet/syntaxnet/
EXPOSE 80 443 9000
VOLUME ["/app/config","/models"]
WORKDIR /app
RUN export LANG=C.UTF-8
CMD ["/usr/bin/supervisord"]
