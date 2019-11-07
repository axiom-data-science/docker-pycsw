# pycsw on Docker

## Quickstart

```bash
$ docker run -p 8000:8000 axiom/docker-pycsw:latest
```

## Production

```
# docker-compose.yml
version: '3'

services:

  db:
    image: kartoza/postgis:11.0-2.5
    stop_signal: SIGINT
    environment:
      POSTGRES_DBNAME: pycsw
      POSTGRES_USER: pycsw
      POSTGRES_PASS: pycsw
    volumes:
      - ./data/db:/var/lib/postgresql

  web:
    image: axiom/docker-pycsw:latest
    volumes:
      - ./postgres.cfg:/opt/pycsw/default.cfg
      - ./data/force:/force
      - ./data/export:/export
      - ./data/store:/store
    ports:
      - "8000:8000"
    depends_on:
      - db
```

```shell
$ docker-compose up -d db
# wait 10 seconds
$ docker-compose up -d web
```


## Configuration

The default configuration file is located [here](https://github.com/axiom-data-science/docker-pycsw/blob/master/default.cfg). Without configuring anything, the `pycsw` server will work on **localhost:8000** and will use SQLite as the backing store, however, it will not contain any useful metadata information about your instance.

There is also a postgres.cfg config file located [here](https://github.com/axiom-data-science/docker-pycsw/blob/master/postgres.cfg) that works with the `docker-compose.yml` file in this repository..

To supply your own configuration file, mount a new configuration at `/opt/pycsw/default.cfg`

```bash
$ docker run \
    ...
    -v /my/config.cfg:/opt/pycsw/default.cfg \
    ...
    axiom/docker-pycsw:latest
```

See the [`pycsw` docs](http://docs.pycsw.org/en/latest/configuration.html) for more information.


### Volumes

#### `/store`

Every **1 hour (:15)** the contents of this directory are added to `pycsw`. Nothing is ever deleted from this directory by `pycsw`. See the [`pycsw` docs](http://docs.pycsw.org/en/latest/administration.html#loading-records) for more information.

```bash
$ docker run \
    ...
    -v /my/store:/store \
    ...
    axiom/docker-pycsw:latest
```


#### `/export`

Every **1 hour (:45)** the contents of your `pycsw` database is exported here as XML files. See the [`pycsw` docs](http://docs.pycsw.org/en/latest/administration.html#exporting-the-repository) for more information.

```bash
$ docker run \
    ...
    -v /my/export:/export \
    ...
    axiom/docker-pycsw:latest
```

#### `/force`

Every **5 minutes (:00)** the contents of this directory are **force** added to `pycsw` and then deleted from the filesystem. See the [`pycsw` docs](http://docs.pycsw.org/en/latest/administration.html#loading-records) for more information.

```bash
$ docker run \
    ...
    -v /my/force:/force \
    ...
    axiom/docker-pycsw:latest
```

#### `/database`

Only valid if using the default SQLite repository configuration. You can **persist** the SQLite database (and therefore the `pycsw` datasets) by mounting an empty directory to `/database`. `pycsw` will create a `cite.db` file that can be reused between `docker run` commands.

```bash
$ docker run \
    ...
    -v /my/database:/database \
    ...
    axiom/docker-pycsw:latest
```
