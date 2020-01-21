FROM alpine as builder

ARG VERSION=v2.7.2

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk --no-cache add \
	build-base \
	git \
	libjpeg-turbo-dev \
	postgresql-dev \
	python3-dev \
	zlib-dev \
	libffi-dev \
	cyrus-sasl-dev \
	libxml2-dev \
	libxslt-dev \
	openldap-dev

RUN git -c advice.detachedHead=false clone --branch "$VERSION" --depth=1 \
	https://github.com/netbox-community/netbox.git /root/netbox

RUN printf "gunicorn\nnapalm\ndjango_auth_ldap\n" >> /root/netbox/requirements.txt
RUN export MAKEFLAGS="-j $(nproc)" && \
	pip3 install --no-warn-script-location --prefix=/root/install \
	-r /root/netbox/requirements.txt

FROM alpine

COPY --from=builder /root/install /usr
COPY --from=builder /root/netbox/netbox /srv/netbox

COPY scripts /usr/local/bin
COPY patches /tmp

RUN scandeps.sh "/usr/lib/python3.8/site-packages" | \
	xargs apk --no-cache add python3 postgresql-client && \
	ln -sf /usr/bin/python3 /usr/local/bin/python && \
	ln -sf /srv/netbox/manage.py /usr/local/bin/netbox && \
	addgroup -S netbox && \
	adduser -S -H -h /srv/netbox -s /sbin/nologin -G netbox -g netbox netbox && \
	mkdir -p /srv/netbox/static && \
	cp /srv/netbox/netbox/configuration.example.py \
		/srv/netbox/netbox/configuration.py && \
	patch -p0 -i /tmp/netbox-defaults.patch && \
	rm -f /tmp/netbox-defaults.patch && \
	chown -R netbox:netbox /srv/netbox

WORKDIR /srv/netbox

USER netbox:netbox

ENTRYPOINT [ "entrypoint.sh" ]
