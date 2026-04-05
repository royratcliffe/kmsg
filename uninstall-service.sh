#!/usr/bin/env sh
set -eu

SERVICE_NAME="kmsg.service"
SCRIPT_NAME="kmsg.pl"
INSTALL_DIR="/opt/kmsg"
UNIT_DIR="/etc/systemd/system"

usage() {
  cat <<'EOF'
Usage: uninstall-service.sh [options]

Options:
  --no-disable  Do not disable the service
  --no-stop     Do not stop the service
  -h, --help    Show this help message
EOF
}

disable_service=1
stop_service=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-disable)
      disable_service=0
      ;;
    --no-stop)
      stop_service=0
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
  echo "Please run as root (for example: sudo ./uninstall-service.sh)" >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is required but was not found." >&2
  exit 1
fi

UNIT_PATH="$UNIT_DIR/$SERVICE_NAME"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"

if [ "$stop_service" -eq 1 ]; then
  if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Stopping $SERVICE_NAME"
    systemctl stop "$SERVICE_NAME"
  else
    echo "$SERVICE_NAME is not active"
  fi
fi

if [ "$disable_service" -eq 1 ]; then
  if systemctl is-enabled --quiet "$SERVICE_NAME"; then
    echo "Disabling $SERVICE_NAME"
    systemctl disable "$SERVICE_NAME"
  else
    echo "$SERVICE_NAME is not enabled"
  fi
fi

if [ -f "$UNIT_PATH" ]; then
  echo "Removing $UNIT_PATH"
  rm -f "$UNIT_PATH"
else
  echo "$UNIT_PATH not found"
fi

if [ -f "$SCRIPT_PATH" ]; then
  echo "Removing $SCRIPT_PATH"
  rm -f "$SCRIPT_PATH"
else
  echo "$SCRIPT_PATH not found"
fi

if [ -d "$INSTALL_DIR" ]; then
  if rmdir "$INSTALL_DIR" 2>/dev/null; then
    echo "Removed empty directory $INSTALL_DIR"
  else
    echo "Keeping non-empty directory $INSTALL_DIR"
  fi
fi

echo "Reloading systemd"
systemctl daemon-reload

echo
echo "Done. Verify removal with:"
echo "  systemctl status $SERVICE_NAME"
echo "  ls -l $UNIT_PATH"
