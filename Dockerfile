FROM slimane/application:latest
MAINTAINER osawagiboy@gmail.com

RUN mkdir -p /slimane
WORKDIR /slimane
ADD . /slimane
RUN make

EXPOSE 3000
CMD .build/release/SlimaneExample $SLIMANE_OPT
