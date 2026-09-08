"""Package shared pure models without maintaining a second implementation."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
site = root / (sys.argv[1] if len(sys.argv)>1 else '.wiki-site')
for name in ['_worker.js', 'balance-api.js']:
    content = (root / 'cloudflare/wiki-auth' / name).read_text(encoding='utf-8')
    content = content.replace('../../docs/javascripts/', './javascripts/')
    (site / name).write_text(content, encoding='utf-8')
print('WIKI_WORKER_PACKAGE_OK')
