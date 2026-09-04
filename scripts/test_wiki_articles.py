"""Verify emitted HTML, not CSS strings: hierarchy, links, anchors and reachability."""
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit

import yaml

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / (sys.argv[1] if len(sys.argv) > 1 else ".wiki-site")
ROOT_SOURCE = "features/index.md"
EXCLUDED = {"index.md", "access/login.md", "access/account.md"}


class Article(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.scope = None
        self.links = {"上": [], "下": []}
        self.ids = set()
        self.current = 0
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            self.ids.add(a["id"])
        if tag == "nav":
            self.scope = {"상위 문서 경로": "上", "하위 문서": "下"}.get(a.get("aria-label"))
        if self.scope and tag == "a":
            self.links[self.scope].append(a["href"])
        if self.scope == "上" and a.get("aria-current") == "page":
            self.current += 1

    def handle_endtag(self, tag):
        if tag == "nav":
            self.scope = None


def route(source):
    return source.removesuffix("index.md") if source.endswith("index.md") else source.removesuffix(".md") + "/"


def target(href, source):
    url = urlsplit(urljoin("https://wiki.test/" + route(source), href))
    assert url.netloc == "wiki.test", f"Navigation left site: {source}: {href}"
    path = SITE / unquote(url.path).lstrip("/")
    if url.path.endswith("/"):
        path /= "index.html"
    assert path.is_file(), f"Broken article link: {source}: {href}"
    if url.fragment:
        assert unquote(url.fragment) in Article(path.read_text(encoding="utf-8")).ids
    return url.path.lstrip("/")


config = yaml.safe_load((ROOT / "mkdocs.yml").read_text(encoding="utf-8"))
parents, children = {}, {}


def walk(items, chain=()):
    landing = None
    for item in items:
        value = next(iter(item.values())) if isinstance(item, dict) else item
        if isinstance(value, str):
            landing = value
            break
    for item in items:
        value = next(iter(item.values())) if isinstance(item, dict) else item
        if isinstance(value, list):
            walk(value, chain + ((landing,) if landing else ()))
        else:
            parents[value] = list(chain) + ([landing] if landing and value != landing else [])
    if landing:
        children[landing] = []
        for item in items:
            value = next(iter(item.values())) if isinstance(item, dict) else item
            if isinstance(value, list):
                first = value[0]
                value = next(iter(first.values())) if isinstance(first, dict) else first
            if value != landing:
                children[landing].append(value)


# Top-level navigation is not a section and must not make the public home
# the parent of every private document.
for item in config["nav"]:
    value = next(iter(item.values()))
    if isinstance(value, list):
        walk(value)
    else:
        parents[value] = []

mapped = json.loads((ROOT / "docs/assets/knowledge-map.json").read_text(encoding="utf-8"))
sources = [d["source"] for c in mapped["root"]["categories"] for g in c["groups"] for d in g["documents"]]
assert set(sources) == set(parents), "Article hierarchy must include every mapped document"
assert len(sources) == len(set(sources)), "Duplicate documents"
count = 0
for source in sources:
    output = SITE / route(source) / "index.html"
    text = output.read_text(encoding="utf-8")
    article = Article(text)
    if source in EXCLUDED:
        assert not article.links["上"] and "sfh-article-body" not in text, source
        continue
    expected = [s for s in parents[source] if s not in EXCLUDED]
    if ROOT_SOURCE not in expected and source != ROOT_SOURCE:
        expected.insert(0, ROOT_SOURCE)
    assert article.current == 1, f"Missing/duplicate current article: {source}"
    assert [target(href, source) for href in article.links["上"]] == [route(s) for s in expected], source
    if re.search(r"^<!-- sfh:children -->$", (ROOT / "docs" / source).read_text(encoding="utf-8"), re.MULTILINE):
        assert [target(href, source) for href in article.links["下"]] == [route(s) for s in children[source]], source
    assert "<!-- sfh:children -->" not in text, f"Unexpanded child list: {source}"
    count += 1

visited = set()


def reachable(source):
    if source in visited:
        return
    visited.add(source)
    for child in children.get(source, []):
        article = Article((SITE / route(source) / "index.html").read_text(encoding="utf-8"))
        assert route(child) in [target(href, source) for href in article.links["下"]], f"Missing actual child link: {source}: {child}"
        reachable(child)


reachable(ROOT_SOURCE)
expected_tree = set(sources) - EXCLUDED - {"development-status.md", "access/planner.md", "access/developer.md"}
assert visited == expected_tree, f"Orphaned article branches: {expected_tree - visited}"
# Planner onboarding must be discoverable and its in-page links must survive build.
tutorial_source = "getting-started/planner-item-balance-tutorial.md"
tutorial_text = (SITE / route(tutorial_source) / "index.html").read_text(encoding="utf-8")
tutorial = Article(tutorial_text)
for anchor in ["choose", "sheet", "balance", "new-item", "drop", "growth", "publish", "troubleshoot"]:
    assert anchor in tutorial.ids, f"Tutorial section missing: {anchor}"
planner_text = (SITE / "access/planner/index.html").read_text(encoding="utf-8")
for anchor in ["balance", "new-item"]:
    link = f"../../{route(tutorial_source)}#{anchor}"
    assert link in planner_text, f"Planner tutorial entry missing: {anchor}"
    target(link, "access/planner.md")
search = json.loads((SITE / "search/search_index.json").read_text(encoding="utf-8"))
assert any(d.get("location", "").startswith(route(tutorial_source)) for d in search["docs"]), "Tutorial not searchable"
for phrase in ["직접 실시간 로더 없음", "CSV 확정", "시트 값을 바꾸지 않았습니다", "P7-01B"]:
    assert phrase in tutorial_text, f"Tutorial boundary missing: {phrase}"
developer_text = (SITE / "access/developer/index.html").read_text(encoding="utf-8")
module_map_position = developer_text.find("data-sfh-code-module-map-host")
developer_console_position = developer_text.find("sfh-role-console is-developer")
assert module_map_position >= 0, "Developer room must embed the live code-module map"
assert developer_console_position >= 0 and module_map_position < developer_console_position, (
    "Code-module map must be the first developer workspace block"
)
print("PLANNER_TUTORIAL_OK anchors_8 planner_entries search_index support_boundaries")
print("DEVELOPER_ROOM_OK code_module_map_first")
print(f"WIKI_ARTICLES_OK pages={len(sources)} breadcrumbs={count} reachable={len(visited)} no_js=true")
