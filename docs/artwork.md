# Landing-page artwork

Final asset: [social.png](assets/social.png) · 1536 × 1024 PNG.

Generated 2026-09-10 through the OpenAI Images API, using the imagegen skill's bundled CLI in API mode. The explicitly requested model was `gpt-image-2.5-sunburst`, with `quality=high`, `size=1536x1024`, and one image per call. The sequence was one generation, an icon-removal correction, and a copy revision following the owner's plain-text-paste positioning feedback. No built-in image-generation tool or alternate model was used.

The API key is external local configuration; it is not part of these prompts or the repository. The final image was visually checked for its text, palette, and absence of an invented icon. It is a brand illustration, not an app screenshot.

## Initial generation prompt

```text
Use case: ads-marketing
Asset type: complete landscape social preview card for the Editan open-source macOS app; 1536 x 1024 or a wide landscape composition suitable for an OG card.
Primary request: Create a sophisticated editorial product illustration for a little writing space where text is drafted, refined, and copied into other apps.
Brand: Editan. Reuse the finished landing page's cool white background (#f7f7ff), vivid indigo ink (#302bbf), and cyan accent (#a4e9ff), matching the existing blue-violet app icon and its cyan arrow.
Scene: A single beautiful ivory paper sheet curves upward into a subtle departing paper arrow, representing text moving from a small writing space into the world. Soft tactile paper, natural shadow, precise sculptural folds, ample clean space, refined independent Mac-app aesthetic.
Composition: Landscape. Large elegantly typeset headline on the left, sculptural paper on the right, generous margins, strong legibility when reduced to a small link preview.
Typography: Editorial serif headline; restrained sans-serif brand and small supporting line. All text below must be exactly correct.
Text (verbatim): "editan." / "Write here." / "Paste anywhere." / "A little space on your Mac."
Constraints: No invented app UI, screenshot, testimonials, download badge, App Store badge, extra copy, third-party logos, or watermark. This is a cohesive finished card with its own typography, not a device mockup. Respect the text and palette exactly. Do not redesign the existing Editan app icon.
```

## Icon correction (edit of the first output)

```text
Remove only the small purple rounded-square arrow icon immediately to the left of the editan. wordmark. Replace its area seamlessly with the existing pale cool-white background. Move the unchanged editan. wordmark left so its left edge aligns with the headline below. Do not add any replacement icon or logo symbol. Preserve the paper sculpture, palette, lighting, typography, exact wording, and every other element. All text must remain exactly: editan. / Write here. / Paste anywhere. / A little space on your Mac.
```

## Product-positioning revision (edit of the corrected output)

```text
Change only the headline and supporting line to match the updated product positioning: Editan accepts pasted text as plain text so you can edit it without inherited fonts or colors. Replace Write here. with Paste it here. Replace Paste anywhere. with Make it yours. Replace A little space on your Mac. with Plain text. Ready for your next step. Keep editan. exactly unchanged. Preserve the same indigo serif typography, cool white background, cyan accents, paper sculpture, overall composition, and generous margins. No extra icon or text. Exact final text: editan. / Paste it here. / Make it yours. / Plain text. Ready for your next step.
```

The English wordmark is intentional in both language versions. The Japanese page supplies localized HTML copy and image alternative text.
