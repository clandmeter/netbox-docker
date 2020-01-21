#!/bin/sh

set -eu

netbox collectstatic --no-input

# wait till postgres is online
while ! pg_isready -qh postgres; do sleep 1; done
netbox migrate
netbox remove_stale_contenttypes --no-input
netbox invalidate all

if [ "$NETBOX_ADMIN_USER" ] && [ "$NETBOX_ADMIN_EMAIL" ] && [ "$NETBOX_ADMIN_PASS" ]; then
	netbox shell <<- EOF
	from django.contrib.auth.models import User
	if not User.objects.filter(username='$NETBOX_ADMIN_USER'):
	  User.objects.create_superuser('$NETBOX_ADMIN_USER', '$NETBOX_ADMIN_EMAIL', '$NETBOX_ADMIN_PASS')
	EOF
else
	echo "Skipping creating admin user. Make sure \$NETBOX_ADMIN_XXX variables are set"
fi

exec gunicorn --bind 0.0.0.0:8080 --workers 5 --threads 3 --timeout 120 \
	--max-requests 5000 --max-requests-jitter 500 netbox.wsgi
