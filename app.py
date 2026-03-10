"""Compatibility wrapper to run the migrated package entrypoint."""

from pyzoommate.app import main

if __name__ == "__main__":
    raise SystemExit(main())
