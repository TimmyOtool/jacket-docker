FROM ubuntu:16.04

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb http://download.mono-project.com/repo/ubuntu xenial main" | tee /etc/apt/sources.list.d/mono-official.list
RUN apt-get update

RUN apt-get install -y mono-devel
ENV _clean="rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"
ENV _apt_clean="eval apt-get clean && $_clean"
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# Install s6-overlay
ENV s6_overlay_version="1.17.1.1"
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz /tmp/
RUN tar zxf /tmp/s6-overlay-amd64.tar.gz -C / && $_clean
ENV S6_LOGGING="1"
# ENV S6_KILL_GRACETIME="3000"


# Install pipework
ADD https://github.com/jpetazzo/pipework/archive/master.tar.gz /tmp/pipework-master.tar.gz
RUN tar -zxf /tmp/pipework-master.tar.gz -C /tmp && cp /tmp/pipework-master/pipework /sbin/ && $_clean


# Install jackett dependancies
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -qqy curl bzip2 sudo libmono-cil-dev libcurl4-openssl-dev \
 && $_apt_clean


# Download jackett
ENV jackett_version="0.8.12"
RUN curl -Lo /tmp/jackett.tar.gz https://github.com/Jackett/Jackett/releases/download/v${jackett_version}/Jackett.Binaries.Mono.tar.gz \
 && mkdir /jackett && tar -xzf /tmp/jackett.tar.gz --strip-components=1 -C /jackett && rm -f /tmp/jackett.tar.gz


# # Download jackett-public
ENV jackett_public_version="0.6.45.3"
RUN curl -Lo /tmp/jackett-public.tar.gz https://github.com/dreamcat4/Jackett-public/releases/download/v${jackett_public_version}/Jackett-public.Binaries.Mono.tar.gz \
 && mkdir /jackett-public && tar -xzf /tmp/jackett-public.tar.gz --strip-components=1 -C /jackett-public && rm -f /tmp/jackett-public.tar.gz


# Setup sonarr /config dir and /media folder
RUN groupadd -o -g 9117 jackett \
 && useradd -o -u 9117 -N -g jackett --shell /bin/sh -d /config jackett \
 && install -o jackett -g jackett -d /config /media


# Global config
#RUN mkdir -p /config/
ADD config /config/


# Start scripts
ENV S6_LOGGING="0"
ADD services.d /etc/services.d


# Launch script
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


# Default container settings
VOLUME /config
EXPOSE 9117 9118
ENTRYPOINT ["/init"]
