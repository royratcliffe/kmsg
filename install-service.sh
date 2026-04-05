#!/usr/bin/env sh
set -eu

SERVICE_NAME="kmsg.service"
SCRIPT_NAME="kmsg.pl"
INSTALL_DIR="/opt/kmsg"
UNIT_DIR="/etc/systemd/system"

usage() {
  cat <<'EOF'
Usage: install-service.sh [options]

Options:
  --no-enable   Do not enable the service
  --no-start    Do not start/restart the service
  -h, --help    Show this help message
EOF
}

enable_service=1
start_service=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-enable)
      enable_service=0
      ;;
    --no-start)
      start_service=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root (for example: sudo ./install-service.sh)" >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is required but was not found." >&2
  exit 1
fi

if ! command -v install >/dev/null 2>&1; then
  echo "install command is required but was not found." >&2
  exit 1
fi

if ! command -v swipl >/dev/null 2>&1; then
  echo "SWI-Prolog (swipl) is required but was not found in PATH." >&2
  exit 1
fi

SWIPL_PATH=$(command -v swipl)

# Determine the directory of this script. This is more robust than using $0
# directly, especially if the script is called via a symlink or from a different
# directory.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
echo "Script directory: $SCRIPT_DIR"

if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
  echo "Cannot find $SCRIPT_NAME next to this installer script." >&2
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/$SERVICE_NAME" ]; then
  echo "Cannot find $SERVICE_NAME next to this installer script." >&2
  exit 1
fi

echo "Installing $SCRIPT_NAME to $INSTALL_DIR"
install -d "$INSTALL_DIR"
install -m 0644 "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"

# The service file is installed with the correct ExecStart path. Use a temporary
# file to avoid modifying the original service file in the scripts directory.
echo "Installing $SERVICE_NAME to $UNIT_DIR"
TMP_SERVICE_FILE=$(mktemp)
trap 'rm -f "$TMP_SERVICE_FILE"' EXIT HUP INT TERM
sed "s|^ExecStart=.*|ExecStart=$SWIPL_PATH -q -s $INSTALL_DIR/$SCRIPT_NAME --|" \
  "$SCRIPT_DIR/$SERVICE_NAME" > "$TMP_SERVICE_FILE"
install -m 0644 "$TMP_SERVICE_FILE" "$UNIT_DIR/$SERVICE_NAME"

echo "Reloading systemd"
systemctl daemon-reload

if [ "$enable_service" -eq 1 ]; then
  echo "Enabling $SERVICE_NAME"
  systemctl enable "$SERVICE_NAME"
fi

if [ "$start_service" -eq 1 ]; then
  echo "Starting (or restarting) $SERVICE_NAME"
  if systemctl is-active --quiet "$SERVICE_NAME"; then
    systemctl restart "$SERVICE_NAME"
  else
    systemctl start "$SERVICE_NAME"
  fi
fi

echo
echo "Done. Check service status with:"
echo "  systemctl status $SERVICE_NAME"
echo "  journalctl -u $SERVICE_NAME -f"
