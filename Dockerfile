FROM lokalebasen/elixir
MAINTAINER Martin Neiiendam mn@lokalebasen.dk
ENV REFRESHED_AT 2015-01-08

ENV MIX_ENV prod
ENV ETCD_ENV syncex

WORKDIR /var/www/app

ADD build.tar /var/www/app/

RUN yes | mix deps.get    &&\
    mix deps.compile      &&\
    mix compile.protocols &&\
    mix release

CMD ["rel/syncex/bin/syncex", "foreground"]
