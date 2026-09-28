#!/usr/bin/env bash
set -e

echo "Waiting for postgres to connect ..."

# Wait for the database to be up and ready, if not ready, then sleep for 5 seconds
while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
  #TODO: Add missing implementation
  echo "Postgres is unavailable --> sleeping"
  sleep 5
done

echo "PostgreSQL is active"

python ./src/manage.py collectstatic --noinput

echo "Running database migrations..."
python ./src/manage.py migrate --noinput

#TODO add migrations
echo "Checking for existing superuser..."
python ./src/manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
username = '${DJANGO_SUPERUSER_USERNAME}'
if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(
        username=username,
        email='${DJANGO_SUPERUSER_EMAIL}',
        password='${DJANGO_SUPERUSER_PASSWORD}'
    )
    print('Superuser created.')
else:
    print('Superuser already exists, skipping.')
"

exec gunicorn --chdir ./src tsa_app.wsgi:application --bind 0.0.0.0:8000
