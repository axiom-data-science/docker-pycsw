#!/bin/sh

# Make everything owned by pycsw user
exec chown -R pycsw:pycsw "$PYCSW_STORE_ROOT" "$PYCSW_FORCE_ROOT" "$PYCSW_EXPORT_ROOT" "$PYCSW_DB_ROOT" 2>&1 | logger -t pycsw_setup

# Setup Database
echo "Setting up DB"
exec /sbin/setuser pycsw pycsw_setup 2>&1 | logger -t pycsw_setup

# Load the store (recursively)
echo "Loading $PYCSW_STORE_ROOT"
exec /sbin/setuser pycsw pycsw_load 2>&1 | logger -t pycsw_load

# Force add any files in the force directory
echo "Loading $PYCSW_FORCE_ROOT"
exec /sbin/setuser pycsw pycsw_force 2>&1 | logger -t pycsw_force

# Optimize the DB
echo "Optimizing DB"
exec /sbin/setuser pycsw pycsw_optimize 2>&1 | logger -t pycsw_optimize

# Export the DB
echo "Exporting DB to $PYCSW_EXPORT_ROOT"
exec /sbin/setuser pycsw pycsw_export 2>&1 | logger -t pycsw_export

echo "Running pycsw"
exec /sbin/setuser pycsw gunicorn \
    -b 0.0.0.0:8000 \
    -w 4 \
    --access-logfile - \
    --error-logfile - \
    pycsw.wsgi:application | logger -t pycsw
