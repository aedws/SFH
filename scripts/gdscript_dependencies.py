"""Shared static references for the architecture gate and wiki graph.

Conservative named-class references, not runtime call-graph inference. Dynamic
Node/provider wiring must still be covered by contract tests and the manifest.
"""
from __future__ import annotations

import re

# Strings first: # inside a quoted URL is not a comment. Preserve newlines when
# masking so declarations/extends continue to have their original line anchors.
TOKENS = re.compile(r'''(?P<string>"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(?P<comment>\#[^\n]*)''')
IDENTIFIER = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
CLASS = re.compile(r"(?m)^class_name\s+(\w+)")
EXTENDS = re.compile(r"(?m)^extends\s+(\w+)")


def scan(source: str) -> tuple[str, set[str]]:
    paths: set[str] = set()

    def mask(match: re.Match) -> str:
        token = match.group(0)
        if match.lastgroup == "string":
            quote = 3 if token[:3] in ('"""', "'''") else 1
            value = token[quote:-quote]
            if value.startswith("res://game/"):
                paths.add(value)
        return "".join("\n" if c == "\n" else " " for c in token)

    return TOKENS.sub(mask, source), paths


def reference_paths(source: str, class_paths: dict[str, str]) -> set[str]:
    code, paths = scan(source)
    own = CLASS.search(code)
    names = set(IDENTIFIER.findall(code))
    if own:
        names.discard(own.group(1))
    return paths | {class_paths[name] for name in names if name in class_paths}


def named_parent(source: str, class_paths: dict[str, str]) -> str:
    parent = EXTENDS.search(scan(source)[0])
    return class_paths.get(parent.group(1), "") if parent else ""


def find_cycle(graph: dict[str, set[str]]) -> list[str]:
    visiting, visited, stack = set(), set(), []

    def visit(node: str) -> list[str]:
        if node in visiting:
            return stack[stack.index(node):] + [node]
        if node in visited:
            return []
        visiting.add(node)
        stack.append(node)
        for target in sorted(graph.get(node, set())):
            found = visit(target)
            if found:
                return found
        stack.pop()
        visiting.remove(node)
        visited.add(node)
        return []

    for node in sorted(graph):
        found = visit(node)
        if found:
            return found
    return []
