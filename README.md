# netbox dockerized

This is an alternative docker images (compared to the official netbox docker
image). Both these images are based on Alpine Linux except this image has some
different design choices.

## Configuration

### Minimal configuration

To get a basic netbox system up and running you need to supply the following
variables:

* `POSTGRES_PASSWORD`
* `POSTGRES_USER`
* `NETBOX_ADMIN_USER`
* `NETBOX_ADMIN_EMAIL`
* `NETBOX_ADMIN_PASS`
* `NETBOX_SECRET_KEY`

### Enviornment variables

The environment variables defined in the docker compose file need to be provided
by a `.env` file in the root of this projects directory.

### Configuration files

#### netbox

In a default simple configuration you do not need to edit any config file as the
defaults are provided by the environment set in the above step. In case you want
to extend or modify netbox configuration you will need to copy netbox
`configuration.example.py` and bind mount it into `netbox/netbox` directory.

#### nginx

A default nginx file is provded and can be used or changed/extended.

## Volumes

This docker-compose.yml does not take care of addidional volumes. If you want
to use any of the additional ones you need to define them in your volumes
section in your docker-compose.yml. Please consult the official docs about
those volumes.

## netbox webhooks (worker)

If you want to make use of netbox webhooks you need to configure the netbox
worker. This is as simple as adding the below service to the compose file and
bringing up the container with docker-compose up -d.

```
netbox-worker:
  <<: *netbox
  depends_on:
    - redis
  entrypoint:
    - netbox
  command:
    - rqworker
```

## Importing

If you are migrating from another system to this docker image you can easily
migrate by adding a volume stanza to the docker-compose.yml like:

```
volumes:
  - ./import:/docker-entrypoint-initdb.d
```

and create a directory called import and move your database sql dump into this
directory. On the first run (when database does not exist yet) it should
automatically pickup this sql file and import it into the database you have
specified in your environment variables. After the import this file will
ignored so you can remove the volume stanza and if needed remove the import
directory.

Dont forget to copy/scp/rsync your media and related files over to the new
container/volumes and possibly enable the volumes in the compose file.

