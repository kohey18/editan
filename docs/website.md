# Website maintenance

The landing page is plain HTML, CSS, and JavaScript. No package installation, framework, external font, tracking script, or runtime backend is required.

- English: `docs/index.html`
- Japanese: `docs/ja/index.html`
- Shared styles and interactions: `docs/assets/site.css` and `site.js`
- Actual app screenshot: `docs/assets/editor.png`, extracted from the repository's existing demo
- Original demo and app icon: `docs/demo.gif`, `docs/icon.png`

The palette follows the existing app icon: indigo (`#302bbf`) for primary actions and headings, cyan (`#a4e9ff`) for accents on dark backgrounds, and a cool white (`#f7f7ff`) base with pale lavender panels. Keep future artwork aligned with these colors.

Edit both language pages together. The format switcher uses fixed examples; it is not a web editor and does not call Claude or Notion. Rich-text copy requires a browser that supports HTML ClipboardItem writes. Failures display a manual-copy message. The demo GIF plays only after the visitor presses Play, and can be stopped.

## Local preview

```sh
python3 Scripts/build_site.py
python3 -m http.server 4173 --bind 127.0.0.1 --directory build/pages
```

Open `http://127.0.0.1:4173/` or `http://127.0.0.1:4173/ja/`.

The build script checks languages, metadata, image alt attributes, duplicate IDs, local links and fragments, and unsafe URL schemes before copying a fixed public-file allowlist to `build/pages/`. It intentionally excludes other documents under `docs/`, including audit and distribution notes.

## GitHub Pages

The intended URLs are `https://kohey18.github.io/editan/` and `/editan/ja/`. Relative asset links work under the repository prefix.

After reviewing the source and history for public release:

1. Merge the reviewed changes into `main`.
2. Make the repository public when the owner is ready.
3. In Settings → Pages, set the source to **GitHub Actions**.
4. Run **Publish website** from Actions, or push a website change to `main`.
5. Check the deployment and both language URLs while signed out.

The workflow refuses to publish from a private repository or another branch. It requests Pages and OIDC permissions only in the deployment job, and pins actions to commits. Changing repository visibility is a separate owner decision, not a side effect of a site build.

See [GitHub's custom Pages workflow documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages).

## Artwork

The owner requested API-based generation using GPT Image 2.5. The selected model is `gpt-image-2.5-sunburst`, documented in the [official model reference](https://developers.openai.com/api/docs/models/gpt-image-2.5-sunburst). Generation is pending a locally configured API key; do not put that key in Git or the site.

The generation prompt follows the icon's indigo/cyan palette above. Once the card is generated and reviewed, save it to `docs/assets/social.png`, record the prompt and generation method, and add absolute Open Graph/X image metadata to both language pages. The current site uses the project's actual app imagery until that asset is ready.
