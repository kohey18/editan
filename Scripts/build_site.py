#!/usr/bin/env python3
"""Validate and stage only the public landing page, using the Python standard library."""
from html.parser import HTMLParser
from pathlib import Path
import shutil
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'docs'
OUTPUT = ROOT / 'build' / 'pages'
FILES = ['index.html', 'ja/index.html', 'icon.png', 'demo.gif',
         'assets/editor.png', 'assets/site.css', 'assets/site.js', '.nojekyll']
# Generated artwork is optional until a model has been approved and an asset reviewed.
if (SOURCE / 'assets' / 'social.png').is_file():
    FILES.append('assets/social.png')

class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.path, self.ids, self.refs, self.lang = path, set(), [], None
        self.has_title = self.has_description = self.has_csp = False

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if tag == 'html': self.lang = attrs.get('lang')
        if tag == 'title': self.has_title = True
        if tag == 'meta':
            if attrs.get('name') == 'description': self.has_description = bool(attrs.get('content'))
            if attrs.get('http-equiv') == 'Content-Security-Policy': self.has_csp = True
        if 'id' in attrs:
            assert attrs['id'] not in self.ids, f'{self.path}: duplicate id {attrs["id"]}'
            self.ids.add(attrs['id'])
        if tag == 'img': assert 'alt' in attrs, f'{self.path}: image missing alt text'
        assert not any(key.startswith('on') for key in attrs), f'{self.path}: inline event handler'
        for key in ['href', 'src', 'data-demo', 'data-still']:
            if key in attrs: self.refs.append(attrs[key])

pages = {}
for filename in FILES:
    path = SOURCE / filename
    assert path.is_file() and not path.is_symlink(), f'Missing or unsafe site file: {filename}'
    if path.suffix == '.html':
        page = Page(path)
        page.feed(path.read_text())
        assert page.lang in ('en', 'ja'), f'{filename}: missing language'
        assert page.has_title and page.has_description and page.has_csp, f'{filename}: missing metadata'
        pages[path.resolve()] = page

allowed = {(SOURCE / filename).resolve() for filename in FILES}
for path, page in pages.items():
    for ref in page.refs:
        url = urlsplit(ref)
        assert url.scheme not in ('javascript', 'data', 'file'), f'{path}: unsafe URL scheme'
        if url.scheme or url.netloc: continue
        target = (path.parent / unquote(url.path)).resolve() if url.path else path
        if target.is_dir(): target = target / 'index.html'
        assert target in allowed, f'{path}: unstaged local link {ref}'
        assert target.is_file(), f'{path}: broken local link {ref}'
        if url.fragment and target in pages:
            assert unquote(url.fragment) in pages[target].ids, f'{path}: missing anchor {ref}'

if OUTPUT.exists(): shutil.rmtree(OUTPUT)
for filename in FILES:
    dest = OUTPUT / filename
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SOURCE / filename, dest)
print(f'Validated {len(pages)} pages; staged {len(FILES)} public files in {OUTPUT.relative_to(ROOT)}')
