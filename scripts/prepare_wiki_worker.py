"""Package shared pure models without maintaining a second implementation."""
from pathlib import Path
import os
import re
import sys
root = Path(__file__).resolve().parents[1]
site = root / (sys.argv[1] if len(sys.argv)>1 else '.wiki-site')
for name in ['_worker.js', 'balance-api.js']:
    content = (root / 'cloudflare/wiki-auth' / name).read_text(encoding='utf-8')
    content = content.replace('../../docs/javascripts/', './javascripts/')
    (site / name).write_text(content, encoding='utf-8')
commit = os.environ.get('GITHUB_SHA')
if commit:
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise ValueError('Invalid wiki build commit')
    index = site / 'index.html'
    html = index.read_text(encoding='utf-8')
    html = re.sub(r'<meta name="sfh-build-commit" content="[0-9a-f]{40}">\s*', '', html)
    if html.count('</head>') != 1:
        raise ValueError('Cannot stamp wiki build identity')
    index.write_text(html.replace('</head>', f'<meta name="sfh-build-commit" content="{commit}">\n</head>'), encoding='utf-8')
print('WIKI_WORKER_PACKAGE_OK')
