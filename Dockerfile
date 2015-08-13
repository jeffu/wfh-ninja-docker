FROM ubuntu:14.04

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

RUN apt-get -y install python postgresql python-pip python-dev postgresql-server-dev-9.3 curl git unzip python-setuptools 

RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

RUN pip install flask
RUN pip install simplejson
RUN pip install flask-cors
RUN pip install flask-login
RUN pip install flask-sqlalchemy
RUN pip install psycopg2

ADD https://github.com/jeffu/wfh-ninja/archive/v0.1.tar.gz ./
RUN tar xzf v0.1.tar.gz && rm v0.1.tar.gz

ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 5000

ENV DATABASE_URL=postgresql://docker:docker@localhost/docker

USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker && cd wfh-ninja-0.1 && python initdb.py &&\
    psql -d docker --command "insert into users(email, password, date_created) values('me@jeff.party', 'firstuser', now());"

USER root

CMD ["/bin/bash", "/start.sh"]
