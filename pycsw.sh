#!/bin/sh

# Setup Database
exec /sbin/setuser pycsw pycsw_setup 2>&1 | logger -t pycsw_setup

# Load the store (recursively)
exec /sbin/setuser pycsw pycsw_load 2>&1 | logger -t pycsw_load

# Force add any files in the force directory
exec /sbin/setuser root pycsw_force 2>&1 | logger -t pycsw_force

# Optimize the DB
exec /sbin/setuser pycsw pycsw_optimize 2>&1 | logger -t pycsw_optimize

# Export the DB
exec /sbin/setuser root pycsw_export 2>&1 | logger -t pycsw_export

# Run
exec /sbin/setuser pycsw gunicorn \
    -b 0.0.0.0:8000 \
    -w 4 \
    --access-logfile - \
    --error-logfile - \
    pycsw.wsgi:application | logger -t pycsw
