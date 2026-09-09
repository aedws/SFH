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
for phrase in [
    "팔란티어식 구조를 기획에 어떻게 쓰나요?",
    "OBJECT · 무엇",
    "LINK · 어떤 관계",
    "ACTION · 무슨 변화",
    "EVIDENCE · 왜 맞는가",
    "기획 제출 전 6문항",
    "작전에서 무기·방어구를 얻는 방식",
    "일반 적 처치 시 현장 전리품은 12% 확률",
    "무기→방어구→모듈→파츠",
    "보스 처치 시 전리품 2개",
    "전투 단검은 장비 정의와 장착 규칙은 있지만 현재 실제 드랍 후보에는 없습니다",
    "살아서 탈출하면 주운 장비가 영구 창고로 이동",
    "Notion에 어떻게 적어야 개발에 반영되나요?",
    "확정 / 임시 / 제안 / 보류 / 변경 / 검수 완료",
    "최소한 이 5줄만 적어 주세요",
    "방 클리어 장비 보상",
    "Notion 저장만으로 자동 배포되지는 않습니다",
    "노션 최신 내용 확인 후 [요청 ID] 반영",
    "name=\"status\"",
    "name=\"unknowns\"",
]:
    assert phrase in planner_text, f"Planner loot guide boundary missing: {phrase}"
search = json.loads((SITE / "search/search_index.json").read_text(encoding="utf-8"))
assert any(d.get("location", "").startswith(route(tutorial_source)) for d in search["docs"]), "Tutorial not searchable"
for phrase in ["직접 실시간 로더 없음", "CSV 확정", "고유 스킬/고정 옵션 열", "P7-01B"]:
    assert phrase in tutorial_text, f"Tutorial boundary missing: {phrase}"
developer_text = (SITE / "access/developer/index.html").read_text(encoding="utf-8")
owner_console_position = developer_text.find("data-sfh-owner-decision-console-host")
module_map_position = developer_text.find("data-sfh-code-module-map-host")
developer_console_position = developer_text.find("SFH 운영 온톨로지 읽는 순서", module_map_position)
assert owner_console_position >= 0, "Developer room must embed the owner decision console"
focus_match = re.search(r'data-focus-object="([^"]+)"', developer_text)
assert focus_match, "Current work overview focus missing"
ontology = json.loads((SITE / "assets/project-ontology.json").read_text(encoding="utf-8"))
assert focus_match.group(1) in {item["id"] for item in ontology["objects"]}, "Overview focus must reference a real object"
assert len(re.findall(r'<details[^>]*class="sfh-developer-fold"', developer_text)) == 2
assert not re.search(r'<details[^>]*class="sfh-developer-fold"[^>]*\sopen[\s>]', developer_text), "Developer details should be collapsed initially"
assert "data-sfh-lazy-code" in developer_text, "Code map must load on disclosure"
for role, text in [("planner", planner_text), ("developer", developer_text)]:
    assert f'data-sfh-workspace="{role}"' in text, "Role layout must be applied after Markdown rendering"
    assert 'class="sfh-workspace-launcher"' in text
    assert 'javascripts/role-workspace.js' in text and 'stylesheets/role-workspace.css' in text
assert '&lt;div class="sfh-planner-filters"' not in planner_text, "Request controls must not become code snippets"
assert 'id="planning-queue"' in planner_text and 'id="proposal-draft"' in planner_text
decision_start = planner_text.index('id="decisions-needed"')
decision_start = planner_text.rfind('<section', 0, decision_start)
decision_end = planner_text.index('</section>', decision_start)
decision_notice = planner_text[decision_start:decision_end]
assert decision_start < planner_text.index('class="sfh-workspace-launcher"'), "Decision notice must precede planner tools"
assert 'aria-labelledby="decisions-needed-title"' in decision_notice
for phrase in ("DEC-N26-POUCH", "DEC-N26-DEPTH", "DEC-N26-BLOOD", "QA-BAL-01",
               "미승인 예시", "프로젝트 오너", "개인 메시지", "Notion", "자동 전송", "미정 14건"):
    assert phrase in decision_notice, f"Planner decision handoff missing: {phrase}"
assert decision_notice.count('<details') == 6, "Keep decision examples in accessible disclosures"
for phrase in ("타겟 갱신 주기", "허수아비 설정", "그래픽/기준 해상도", "상점 리롤 비용", "탈출 증원 배율",
               "최대 스킬 슬롯", "광역 탐색 반경", "실서버 랭킹/무결성", "룬 환전 가치", "준비 UI",
               "AP 최대·회복", "탈출 방어 시간", "씬 전환 연출", "손상 장비 페널티"):
    assert phrase in decision_notice, f"Undecided tracker question missing: {phrase}"
assert not re.search(r'<details[^>]*\sopen[\s>]', decision_notice), "Examples should be collapsed initially"
assert 'href="https://wobbly-pawpaw-1ff.notion.site/3d35b728004081eba698e9a00f6ec0ed"' in decision_notice
assert module_map_position >= 0, "Developer room must embed the live code-module map"
assert developer_console_position >= 0 and owner_console_position < module_map_position < developer_console_position, (
    "Owner decisions must precede implementation evidence and the developer operating guide"
)
for phrase in ["SFH 운영 온톨로지 읽는 순서", "판단 폐루프", "객체 탐색", "관계·계보", "행동·관측"]:
    assert phrase in developer_text, f"Developer operational ontology guidance missing: {phrase}"
assert (SITE / "assets/project-ontology.json").is_file(), "Generated project ontology missing"
audit = json.loads((ROOT / "docs/assets/notion-code-audit.json").read_text(encoding="utf-8"))
tracker = json.loads((ROOT / "docs/assets/notion-tracker-snapshot.json").read_text(encoding="utf-8"))
category_by_id = {row["id"]: row["category"] for row in tracker["rows"]}
topic_categories = {
    "features/index.md": None,
    "features/operations.md": {"플레이어루프", "탈출/파산방지", "원정계약/랭킹"},
    "features/combat.md": {"스마트타겟팅", "조작/스킬바인딩"},
    "features/loot.md": {"전리품/파밍"},
    "features/growth.md": {"상점/제작소", "훈련연습장"},
    "architecture/index.md": {"엔진/아키텍처"},
}
for source, categories in topic_categories.items():
    text = (SITE / route(source) / "index.html").read_text(encoding="utf-8")
    expected_rows = [r for r in audit["rows"] if categories is None or category_by_id[r["notion_id"]] in categories]
    assert f'data-sfh-stage-count="{len(expected_rows)}"' in text, source
    assert "<!-- sfh:implementation -->" not in text
    for row in expected_rows:
        if row["assessment"] != "code_supported":
            from html import escape
            assert escape(row["title"]) in text, f"Missing remaining boundary: {row['title']}"
public_home = (SITE / "index.html").read_text(encoding="utf-8")
root_text = (SITE / "features/index.html").read_text(encoding="utf-8")
assert "직접 조준하는 대신 이동·회피와 스킬 사용에 집중하는 전투를 설명합니다." in root_text, "Child descriptions must load before child pages render"
assert 'return=%2Ffeatures%2F' in public_home
assert 'data-sfh-stage-count' not in public_home, "Implementation data must stay protected"
assert (SITE / "javascripts/owner-decision-console.js").is_file(), "Owner decision console runtime missing"
print("PLANNER_TUTORIAL_OK anchors_8 planner_entries loot_flow notion_authoring search_index support_boundaries")
print("DEVELOPER_ROOM_OK owner_decisions_then_code_evidence")
print(f"WIKI_ARTICLES_OK pages={len(sources)} breadcrumbs={count} reachable={len(visited)} no_js=true")
