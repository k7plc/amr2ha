# Docker file to create a hass.io add-on to listen to events via RTL_SDR/RTL_AMR
# and then publish them to the Home Assistant REST API.
# The script resides in a volume and can be modified to meet your needs.
# This addon is based on: https://github.com/chriskacerguis/honeywell2mqtt
# which is in turn based on: https://github.com/roflmao/rtl2mqtt

# IMPORTANT: The container needs privileged access to /dev/bus/usb on the host.

ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8


LABEL Description="This image is used to start a script that will monitor for \
RF events on 912Mhz and send the data to The Home Assistant REST API"

#
# First install software packages needed to compile rtl_sdr
#
RUN apk add --no-cache --virtual build-deps alpine-sdk cmake git libusb-dev && \
    mkdir /tmp/src && \
    cd /tmp/src && \
    git clone https://github.com/rtlsdrblog/rtl-sdr-blog.git && \
    cd /tmp/src/rtl-sdr/ && \
    git checkout remotes/origin/wip_rtltcp_ringbuf && \
    mkdir /tmp/src/rtl-sdr/build && \
    cd /tmp/src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr/local && \
    make && \
    make install && \
    chmod +s /usr/local/bin/rtl_* && \
    apk del build-deps && \
    rm -r /tmp/src && \
    apk add --no-cache bash libusb mosquitto-clients jq coreutils wget make musl-dev go git gcc usb-modeswitch

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

RUN go install github.com/bemasher/rtlamr@latest


COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
