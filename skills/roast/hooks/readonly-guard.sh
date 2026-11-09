#!/usr/bin/env bash
# Entry point named in the critic agent definition; the guard itself is Python.
exec python3 "$(dirname "$0")/readonly_guard.py"
