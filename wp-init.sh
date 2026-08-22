#!/bin/bash
# Runs once via the `wpcli` service: waits for WordPress core to be reachable,
# installs it if needed, then installs & activates the git-it-write plugin.
#
# Note: we don't use `wp db check` here — the wordpress:cli (Alpine) image's
# bundled mysql client fails against mysql:8.0 (TLS cert + missing
# caching_sha2_password plugin). `wp core`/`wp plugin` instead go through
# WordPress's own PHP mysqli connection, which works fine, so DB readiness is
# checked via `wp core is-installed`'s own output instead.
set -uo pipefail

WP="wp --path=/var/www/html"

echo "[wp-init] Waiting for WordPress files..."
until [ -f /var/www/html/wp-load.php ]; do sleep 2; done

echo "[wp-init] Waiting for the database to accept connections..."
tries=0
while true; do
  output=$($WP core is-installed 2>&1)
  installed=$?
  if ! grep -q "Error establishing a database connection" <<<"$output"; then
    break
  fi
  tries=$((tries + 1))
  if [ "$tries" -ge 30 ]; then
    echo "[wp-init] Timed out waiting for the database." >&2
    exit 1
  fi
  sleep 2
done

if [ "$installed" -eq 0 ]; then
  echo "[wp-init] WordPress already installed, skipping core install."
else
  echo "[wp-init] Installing WordPress core..."
  $WP core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email
fi

echo "[wp-init] Installing/activating git-it-write plugin..."
$WP plugin install git-it-write --activate

echo "[wp-init] Done."
