'use strict';
const japanese = document.documentElement.lang === 'ja';
const samples = {
  plain: { title: 'FOR YOUR NEXT PROMPT', ja: '次のプロンプトに', shortcut: '⌘ C', text: '# Ready to ship\n\n**Small improvements. Big difference.**\n\n- Polish the details\n- Share with the team', note: 'Markdown stays Markdown. The clipboard gets plain text.', noteJa: 'Markdown はそのまま。クリップボードにはプレーンテキストだけ。' },
  slack: { title: 'FOR THE TEAM CHANNEL', ja: 'チームのチャンネルに', shortcut: '⇧ ⌘ C', text: '*Ready to ship*\n\n*Small improvements. Big difference.*\n\n• Polish the details\n• Share with the team', note: 'Slack-style text, ready to paste. Nothing is posted for you.', noteJa: 'Slack 向けの書式でコピー。メッセージは自動送信しません。' },
  rich: { title: 'FOR YOUR NEXT EMAIL', ja: '次のメールに', shortcut: '⌥ ⌘ C', note: 'Formatted HTML plus a plain-text fallback, for apps that accept rich text.', noteJa: 'HTML とプレーンテキストを一緒にコピー。リッチテキスト対応のアプリに。' },
  notion: { title: 'A NEW PAGE IN NOTION', ja: 'Notion の新しいページに', shortcut: '⇧ ⌘ N', note: 'In the Mac app, this creates a page under your configured parent. This example sends nothing.', noteJa: 'Mac アプリでは設定した親ページの配下に作成します。このデモは送信しません。' }
};
let current = 'plain';
const tabs = [...document.querySelectorAll('[data-format]')];
function selectFormat(tab, focus = false) {
  current = tab.dataset.format;
  const sample = samples[current];
  for (const item of tabs) {
    const selected = item === tab;
    item.setAttribute('aria-selected', String(selected));
    item.tabIndex = selected ? 0 : -1;
  }
  document.getElementById('format-panel').setAttribute('aria-labelledby', tab.id);
  document.getElementById('format-destination').textContent = japanese ? sample.ja : sample.title;
  document.getElementById('format-shortcut').textContent = sample.shortcut;
  const plain = document.getElementById('format-plain');
  plain.hidden = !sample.text;
  plain.textContent = sample.text || '';
  document.getElementById('format-rich').hidden = Boolean(sample.text);
  document.getElementById('format-note').textContent = japanese ? sample.noteJa : sample.note;
  const button = document.getElementById('copy-example');
  button.hidden = current === 'notion' || !navigator.clipboard?.writeText;
  button.textContent = current === 'rich' ? (japanese ? 'リッチテキストをコピー ↗' : 'Copy rich text ↗') : (japanese ? 'サンプルをコピー ↗' : 'Copy example ↗');
  document.getElementById('copy-status').textContent = '';
  if (focus) tab.focus();
}
for (const [index, tab] of tabs.entries()) {
  tab.addEventListener('click', () => selectFormat(tab));
  tab.addEventListener('keydown', event => {
    let next;
    if (event.key === 'ArrowRight') next = (index + 1) % tabs.length;
    if (event.key === 'ArrowLeft') next = (index + tabs.length - 1) % tabs.length;
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = tabs.length - 1;
    if (next !== undefined) { event.preventDefault(); selectFormat(tabs[next], true); }
  });
}
async function copyContent(statusId, write) {
  const status = document.getElementById(statusId);
  try { await write(); status.textContent = japanese ? 'コピーしました。' : 'Copied to clipboard.'; }
  catch { status.textContent = japanese ? 'コピーできませんでした。テキストを選択してコピーしてください。' : 'Clipboard unavailable. Select the text and copy it manually.'; }
}
document.getElementById('copy-example').addEventListener('click', () => {
  copyContent('copy-status', async () => {
    if (current === 'rich') {
      if (!window.ClipboardItem || !navigator.clipboard.write) throw new Error('Rich clipboard unavailable');
      const html = '<h1>Ready to ship</h1><p><strong>Small improvements. Big difference.</strong></p><ul><li>Polish the details</li><li>Share with the team</li></ul>';
      await navigator.clipboard.write([new ClipboardItem({ 'text/html': new Blob([html], { type: 'text/html' }), 'text/plain': new Blob([samples.plain.text], { type: 'text/plain' }) })]);
    } else { await navigator.clipboard.writeText(samples[current].text); }
  });
});
const install = document.getElementById('copy-install');
install.hidden = !navigator.clipboard?.writeText;
install.addEventListener('click', () => copyContent('install-status', () => navigator.clipboard.writeText(document.getElementById('install-command').textContent)));
const replay = document.querySelector('[data-demo]');
replay.hidden = false;
replay.addEventListener('click', () => {
  const playing = replay.getAttribute('aria-pressed') === 'true';
  document.getElementById('editor-image').src = playing ? replay.dataset.still : replay.dataset.demo;
  replay.setAttribute('aria-pressed', String(!playing));
  replay.textContent = playing ? (japanese ? 'デモを再生 ↗' : 'Play demo ↗') : (japanese ? '停止 ■' : 'Stop demo ■');
});
selectFormat(tabs[0]);
