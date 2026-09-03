"""Build-time article navigation. MkDocs nav owns the hierarchy; no client fetch.

Keep public/auth surfaces outside the private article wrapper. This is presentation,
not authorization: the Cloudflare worker continues to enforce access on every route.
"""
from html import escape

from mkdocs.utils import get_relative_url

ROOT_SOURCE = "features/index.md"
EXCLUDED = {"index.md", "access/login.md", "access/account.md"}
_pages = {}


def on_nav(nav, **kwargs):
    global _pages
    _pages = {page.file.src_uri: page for page in nav.pages}
    return nav


def _landing(section):
    if section and section.children and section.children[0].is_page:
        return section.children[0]
    return None


def _link(target, page):
    url = escape(get_relative_url(target.url, page.url), quote=True)
    return f'<a href="{url}">{escape(str(target.title))}</a>'


def on_page_content(html, page, **kwargs):
    if page.file.src_uri in EXCLUDED:
        return html
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
                children.append(f'<li>{_link(target, page)}</li>')
        html = html.replace(
            "<!-- sfh:children -->",
            '<nav class="sfh-article-children" aria-label="하위 문서"><ul>'
            + "".join(children) + '</ul></nav>',
        )
    return navigation + '<div class="sfh-article-body">' + html + '</div>'
