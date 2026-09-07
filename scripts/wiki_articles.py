"""Build-time article navigation. MkDocs nav owns the hierarchy; no client fetch.

Keep public/auth surfaces outside the private article wrapper. This is presentation,
not authorization: the Cloudflare worker continues to enforce access on every route.
"""
from html import escape
from collections import Counter
import json
from pathlib import Path
import yaml

from mkdocs.utils import get_relative_url

ROOT_SOURCE = "features/index.md"
EXCLUDED = {"index.md", "access/login.md", "access/account.md"}
_pages = {}
_audit = {}
_categories = {}
_descriptions = {}
TOPIC_CATEGORIES = {
    "features/operations.md": {"플레이어루프", "탈출/파산방지", "원정계약/랭킹"},
    "features/combat.md": {"스마트타겟팅", "조작/스킬바인딩"},
    "features/loot.md": {"전리품/파밍"},
    "features/growth.md": {"상점/제작소", "훈련연습장"},
    "architecture/index.md": {"엔진/아키텍처"},
}
STATE_LABELS = {
    "code_supported": "구현 근거", "partial": "부분 구현", "missing": "미구현",
    "conflict": "충돌 판단", "decision_pending": "기획 미정",
}


def on_nav(nav, **kwargs):
    global _pages, _audit, _categories, _descriptions
    _pages = {page.file.src_uri: page for page in nav.pages}
    # Later pages have not been rendered yet; their page.meta may still be empty.
    _descriptions = {}
    for source, target in _pages.items():
        content = Path(target.file.abs_src_path).read_text(encoding="utf-8-sig")
        metadata = yaml.safe_load(content.split("---", 2)[1]) if content.startswith("---") else {}
        _descriptions[source] = str((metadata or {}).get("description", "설명과 하위 문서 보기"))
    assets = Path(__file__).resolve().parents[1] / "docs/assets"
    _audit = json.loads((assets / "notion-code-audit.json").read_text(encoding="utf-8"))
    tracker = json.loads((assets / "notion-tracker-snapshot.json").read_text(encoding="utf-8"))
    if _audit["tracker_sha256"] != tracker["content_sha256"]:
        raise ValueError("Implementation guide must use the current reviewed tracker")
    _categories = {row["id"]: row["category"] for row in tracker["rows"]}
    return nav


def _landing(section):
    if section and section.children and section.children[0].is_page:
        return section.children[0]
    return None


def _link(target, page):
    url = escape(get_relative_url(target.url, page.url), quote=True)
    return f'<a href="{url}">{escape(str(target.title))}</a>'


def _implementation_guide(page):
    source = page.file.src_uri
    if source != ROOT_SOURCE and source not in TOPIC_CATEGORIES:
        raise ValueError(f"Implementation guide has no topic mapping: {source}")
    rows = [row for row in _audit["rows"] if source == ROOT_SOURCE or
            _categories[row["notion_id"]] in TOPIC_CATEGORIES[source]]
    counts = Counter(row["assessment"] for row in rows)
    badges = ''.join(f'<li><b>{counts[state]}</b> {label}</li>' for state, label in STATE_LABELS.items())
    pending = [row for row in rows if row["assessment"] != "code_supported"]
    items = ''.join(
        f'<li><b>{escape(row["title"])}</b><span>{STATE_LABELS[row["assessment"]]} · '
        f'{escape(row["next_packet"])}</span><p>{escape(row["finding"])}</p></li>' for row in pending)
    audit_link = _link(_pages["design/master-gdd-alignment.md"], page)
    return (f'<section class="sfh-implementation-guide" aria-label="현행 구현 단계" data-sfh-stage-count="{len(rows)}">'
            f'<h2>현행 구현 단계</h2><p>검토일 {_audit["reviewed_at"]} · 요구 {len(rows)}개. '
            '코드 근거와 기획 미정을 구분합니다. 출시·사람 플레이 합격률이 아닙니다.</p>'
            f'<ul class="sfh-stage-counts">{badges}</ul>'
            f'<details><summary>남은 경계 {len(pending)}개 확인</summary><ul class="sfh-stage-remaining">{items}</ul></details>'
            f'<p>원문·코드·판정 근거: {audit_link}</p></section>')


def on_page_content(html, page, **kwargs):
    if page.file.src_uri in EXCLUDED:
        return html
    if "<!-- sfh:implementation -->" in html:
        html = html.replace("<!-- sfh:implementation -->", _implementation_guide(page))
    root = _pages[ROOT_SOURCE]
    ancestors = []
    section = page.parent
    while section:
        landing = _landing(section)
        if landing and landing is not page and landing.file.src_uri not in EXCLUDED:
            ancestors.insert(0, landing)
        section = section.parent
    if page is not root and root not in ancestors:
        ancestors.insert(0, root)
    crumbs = "".join(f"<li>{_link(p, page)}</li>" for p in ancestors)
    crumbs += f'<li aria-current="page">{escape(str(page.title))}</li>'
    navigation = (
        '<nav class="sfh-article-path" aria-label="상위 문서 경로">'
        f'<ol>{crumbs}</ol></nav>'
    )
    if "<!-- sfh:children -->" in html:
        # Only a section's landing article owns its children. Changes to nav
        # automatically change both sidebar and in-article child links.
        if _landing(page.parent) is not page:
            raise ValueError(f"Article hub is not the first nav page: {page.file.src_uri}")
        children = []
        for item in page.parent.children:
            target = _landing(item) if item.is_section else item
            if target and target.is_page and target is not page:
                description = escape(_descriptions[target.file.src_uri])
                children.append(f'<li>{_link(target, page)}<p>{description}</p></li>')
        html = html.replace(
            "<!-- sfh:children -->",
            '<nav class="sfh-article-children" aria-label="하위 문서"><ul>'
            + "".join(children) + '</ul></nav>',
        )
    return navigation + '<div class="sfh-article-body">' + html + '</div>'
