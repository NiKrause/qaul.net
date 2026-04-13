#!/bin/sh
set -e
# Select baked-in config template (under /etc/qaul/) with QAUL_CONFIG_PRESET, then optionally
# copy to /srv/qaul/config.yaml. Also writes /srv/qaul/version when seeding (see libqaul upgrade).
#
# QAUL_CONFIG_PRESET (case-insensitive):
#   default | community | ""  -> /etc/qaul/config.default.yaml  (IPv4 bootstrap on)
#   stock                      -> /etc/qaul/config.stock.yaml   (no bootstrap peers)
#   dual | both                -> /etc/qaul/config.dual.yaml    (IPv4 + IPv6 bootstrap on)
#
# QAUL_OVERWRITE_DEFAULT_CONFIG=1|true|yes|on -> always copy template (destructive).
# If unset / false: copy only when /srv/qaul/config.yaml is missing.

preset=$(printf '%s' "${QAUL_CONFIG_PRESET:-default}" | tr '[:upper:]' '[:lower:]')
case "$preset" in
  default|community|'') template=/etc/qaul/config.default.yaml ;;
  stock) template=/etc/qaul/config.stock.yaml ;;
  dual|both) template=/etc/qaul/config.dual.yaml ;;
  *)
    echo "entrypoint: unknown QAUL_CONFIG_PRESET='$QAUL_CONFIG_PRESET' (try default, stock, dual)" >&2
    exit 1
    ;;
esac

if [ ! -f "$template" ]; then
  echo "entrypoint: missing template $template" >&2
  exit 1
fi

seeded=0
if [ "$QAUL_OVERWRITE_DEFAULT_CONFIG" = "1" ] \
  || [ "$(printf '%s' "$QAUL_OVERWRITE_DEFAULT_CONFIG" | tr '[:upper:]' '[:lower:]')" = "true" ] \
  || [ "$(printf '%s' "$QAUL_OVERWRITE_DEFAULT_CONFIG" | tr '[:upper:]' '[:lower:]')" = "yes" ] \
  || [ "$(printf '%s' "$QAUL_OVERWRITE_DEFAULT_CONFIG" | tr '[:upper:]' '[:lower:]')" = "on" ]; then
  cp "$template" /srv/qaul/config.yaml
  seeded=1
elif [ ! -f /srv/qaul/config.yaml ]; then
  cp "$template" /srv/qaul/config.yaml
  seeded=1
fi

if [ "$seeded" = "1" ]; then
  printf %s "${LIBQAUL_PKG_VERSION:?LIBQAUL_PKG_VERSION must be set in the image}" > /srv/qaul/version
fi

exec /usr/local/bin/qauld --name "$NAME" --port "$PORT"
