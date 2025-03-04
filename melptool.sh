#! /bin/sh

command=$1

case "$command" in
    s|serial)
        gtkterm -p /dev/ttyUSB0 -s 115200
        ;;
    *)
        echo "Unknown command" >&2
        exit 1
        ;;
esac
