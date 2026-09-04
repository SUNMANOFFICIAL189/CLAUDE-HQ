#!/usr/bin/env python3
"""HQ Hermes pilot -- T8 config-key audit tool.

Prints every dotted leaf key of a YAML file, one per line, sorted.
A list value counts as a leaf at its own key (its elements are never
expanded into indexed sub-keys) -- e.g. `approvals.deny: [...]` prints
as the single leaf `approvals.deny`, not `approvals.deny.0`, `.1`, ...

Usage:
    HERMES_HOME=$HH $PY config-keys.py <path-to-yaml>

Uses PyYAML (yaml.safe_load) -- no other dependency.
"""
import sys

import yaml


def leaf_keys(node, prefix=""):
    """Yield every dotted leaf-key path under `node`.

    A dict recurses into its values. Anything else (scalar, list, null,
    bool, ...) is a leaf at `prefix`. An empty dict is itself a leaf
    (nothing to recurse into) when it has a prefix; an empty top-level
    document yields nothing.
    """
    if isinstance(node, dict):
        if not node:
            if prefix:
                yield prefix
            return
        for key, value in node.items():
            child_prefix = f"{prefix}.{key}" if prefix else str(key)
            yield from leaf_keys(value, child_prefix)
    else:
        if prefix:
            yield prefix


def main(argv):
    if len(argv) != 2:
        print("usage: config-keys.py <yaml-file>", file=sys.stderr)
        return 2

    path = argv[1]
    with open(path, "r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh)

    if data is None:
        data = {}

    for key in sorted(leaf_keys(data)):
        print(key)

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
