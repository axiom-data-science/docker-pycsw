#!/bin/bash
set -e

if [ "$1" = 'gunicorn' ]; then
    python bin/pycsw-admin.py -c load_records -f default.cfg -p /records
    python bin/pycsw-admin.py -c optimize_db -f default.cfg
    exec gosu pycsw "$@"
fi

exec "$@"
