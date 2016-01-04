# pycsw on Docker

### tl;dr

**Quickstart**

```bash
$ docker run \
    -p 8000:8000 \
    axiom/docker-pycsw
```

**Production**

```bash
$ docker run \
    -d \
    -p 8000:8000 \
    -v /my/config.cfg:/opt/pycsw/default.cfg \
    -v /my/force:/force \
    -v /my/export:/export \
    -v /my/store:/store \
    -v /my/database:/database \
    --name pycsw \
    axiom/docker-pycsw
```

## Configuration

The default configuration file is located [here](https://github.com/axiom-data-science/docker-pycsw/blob/master/default.cfg). Without configuring anything, the `pycsw` server will work on **localhost:8000**, however, it will not contain any useful metadata information about your instance.

To supply your own configuration file, mount a new configuration at `/opt/pycsw/default.cfg`

```bash
$ docker run \
    ...
    -v /my/config.cfg:/opt/pycsw/default.cfg \
    ...
    axiom/docker-pycsw
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
    axiom/docker-pycsw
```


#### `/export`

Every **1 hour (:45)** the contents of your `pycsw` database is exported here as XML files. See the [`pycsw` docs](http://docs.pycsw.org/en/latest/administration.html#exporting-the-repository) for more information.

```bash
$ docker run \
    ...
    -v /my/export:/export \
    ...
    axiom/docker-pycsw
```

#### `/force`

Every **5 minutes (:00)** the contents of this directory are **force** added to `pycsw` and then deleted from the filesystem. See the [`pycsw` docs](http://docs.pycsw.org/en/latest/administration.html#loading-records) for more information.

```bash
$ docker run \
    ...
    -v /my/force:/force \
    ...
    axiom/docker-pycsw
```

#### `/database`

Only valid if using the default SQLite repository configuration. You can **persist** the SQLite database (and therefore the `pycsw` datasets) by mounting an empty directory to `/database`. `pycsw` will create a `cite.db` file that can be reused between `docker run` commands.

```bash
$ docker run \
    ...
    -v /my/database:/database \
    ...
    axiom/docker-pycsw
```
