FROM cyberdojo/ruby-base:latest
LABEL maintainer=jon@jaggersoft.com
COPY --chown=nobody:nogroup . /app
