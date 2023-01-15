#!/bin/bash

# This file attempts to upgrade database from a different version to current.
# It should be used when Artifactory changes database version.
# Upgrade will only be performed if detected necessary, based on current DB_DIR contents
# and version specified in target database image. Backup will be stored in ${DB_DIR}.old.

set -e
SCRIPT_DIR=$(dirname "$0")

# Defaults if not provided in environment already
: ${DATA_ROOT_DIR:=/data}
: ${DB_DIR:=${DATA_ROOT_DIR}/postgresql}
: ${COMPOSE_FILE:=${SCRIPT_DIR}/artifactory-pro.yml}

echo "Checking whether ${DB_DIR} requires upgrade..."
old_pg_version=$(cat ${DB_DIR}/PG_VERSION)
if [ -z "${old_pg_version}" ]; then
    echo "ERROR: Failed to detect old database version." >&2
    exit 1
fi

new_pg_version=$(docker-compose -f "${COMPOSE_FILE}" run --rm --no-deps postgresql sh -c 'echo $PG_MAJOR' | tr -d '\r')
if [ -z "${new_pg_version}" ]; then
    echo "ERROR: Failed to detect new database version." >&2
    exit 1
elif [ "${old_pg_version}" == "${new_pg_version}" ]; then
    echo "No database upgrade necessary."
    exit 0
else
    echo "Upgrade required: ${old_pg_version} to ${new_pg_version}."
fi

# Sanitize environment
forbidden_containers=(artifactory postgresql)
running_containers=()
for container in ${forbidden_containers[@]}; do
    running_containers+=($(docker ps -q -f name=$container))
done

if [ ${#running_containers[@]} -ne 0 ]; then
    echo "ERROR: The following containers must be stopped before upgrade: ${running_containers[@]}." >&2
    exit 1
fi

if [ -e "${DB_DIR}.old" ]; then
    echo "ERROR: ${DB_DIR}.old already exists. Please remove it so that backup can be created."
    exit 1
fi

# Restore backup in case of any error
function cleanup {
    exit_code=$?
    echo "Cleaning up..."
    [ -n "${tmpfile}" ] && rm -f "${tmpfile}"
    [ -n "${started_container}" ] && (docker stop "${started_container}"; docker rm --force "${started_container}") >/dev/null
    [ -n "${dump_volume}" ] && docker volume rm -f "${dump_volume}" >/dev/null

    if [ ${exit_code} -ne 0 ]; then
        if [ -d "${DB_DIR}.old" ]; then
            echo "Restoring ${DB_DIR}..."
            rm -rf "${DB_DIR}"
            mv -fv "${DB_DIR}.old" "${DB_DIR}"
        fi
    fi

    echo "Done."

    # Cleanup may have been initiated by signal. Do not clean up again on EXIT.
    trap '' EXIT

    exit ${exit_code}
}
trap cleanup INT TERM EXIT

# Attempt to find old database image
old_pg_image=$(docker images docker.bintray.io/postgres --format '{{.Repository}}:{{.Tag}}' | grep -E ":${old_pg_version}" | sort -nr | head -n 1)
if [ -z "${old_pg_image}" ]; then
    echo "ERROR: Could not find already downloaded Artifactory-provided PostgreSQL image." >&2
    exit 1
fi

echo "Dumping database using ${old_pg_image}..."

# Start up old image on existing data
tmpfile=$(mktemp)
dump_volume=$(basename "${tmpfile}")
printf "version: '2.1'\nservices:\n  postgresql:\n    image: ${old_pg_image}\n" > "${tmpfile}"
started_container=$(docker-compose -f "${COMPOSE_FILE}" -f "${tmpfile}" run -d -v "${dump_volume}:/tmp/dump" --no-deps postgresql)

# Dump database to a text file in a volume (to make it available for import)
docker exec "${started_container}" bash -c "until pg_isready -q; do sleep 1; done"
docker exec "${started_container}" bash -c "pg_dumpall --clean --if-exists --username=\${POSTGRES_USER} > /tmp/dump/dump.sql"
docker stop "${started_container}" >/dev/null
docker rm --force "${started_container}" >/dev/null
unset started_container

echo "Backing up data folder ${DB_DIR}..."
mv -fv "${DB_DIR}" "${DB_DIR}.old"

echo "Setting up new database directory..."
mkdir -p "${DB_DIR}"
chown --reference="${DB_DIR}.old" "${DB_DIR}"
chmod --reference="${DB_DIR}.old" "${DB_DIR}"

# Artifactory postgres image sets up a database in its entrypoint, executing also SQL scripts from /docker-entrypoint-initdb.d directory.
# It proceeds only if command name is 'postgres' (the database driver), but actually we don't want to start database afterwards,
# hence calling it with '--version' to just print out version and quit (yet data import has already happened).
# Note: Overriding POSTGRES_DB and POSTGRES_USER as the import will fail on deleting actual database and role otherwise.
echo "Importing data..."
docker-compose -f "${COMPOSE_FILE}" run --rm --no-deps -e POSTGRES_DB=postgres -e POSTGRES_USER=root -v "${dump_volume}:/docker-entrypoint-initdb.d" postgresql postgres --version

# All the cleanup will be performed by EXIT trap.
