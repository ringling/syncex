FROM lokalebasen/elixir
MAINTAINER Martin Neiiendam mn@lokalebasen.dk
ENV REFRESHED_AT 2015-01-08

ENV MIX_ENV prod
ENV ETCD_ENV syncex

WORKDIR /var/www/app

ADD build.tar /var/www/app/

# Erlang communication ports
EXPOSE 4369 55950 55951 55952 55953 55954

RUN yes | mix deps.get    &&\
    mix deps.compile      &&\
    mix compile.protocols &&\
    mix release

CMD ["rel/syncex/bin/syncex", "foreground"]
