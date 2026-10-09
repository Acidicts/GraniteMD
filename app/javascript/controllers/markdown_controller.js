import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "body"];

  connect() {
    this.update();
  }

  update() {
    this.bodyTarget.innerHTML = markdownToHtml(this.inputTarget.value);
  }
}

function markdownToHtml(md) {
  const stash = [];
  const hold = (html) => `\u0000${stash.push(html) - 1}\u0000`;
  const escapeHtml = (s) =>
    s
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  const safeUrl = (u) => (/^\s*(javascript|data|vbscript):/i.test(u) ? "#" : u);

  // Inline: `code`, images, links, **bold**, *italic*, ~~strike~~
  function inline(text) {
    text = text.replace(/`([^`]+)`/g, (_, c) =>
      hold(`<code>${escapeHtml(c)}</code>`),
    );
    text = escapeHtml(text);
    return text
      .replace(
        /!\[([^\]]*)\]\(([^)\s]+)\)/g,
        (_, alt, src) => `<img src="${safeUrl(src)}" alt="${alt}">`,
      )
      .replace(
        /\[([^\]]+)\]\(([^)\s]+)\)/g,
        (_, t, href) => `<a href="${safeUrl(href)}">${t}</a>`,
      )
      .replace(
        /\*\*(.+?)\*\*|__(.+?)__/g,
        (_, a, b) => `<strong>${a || b}</strong>`,
      )
      .replace(/\*(.+?)\*|\b_(.+?)_\b/g, (_, a, b) => `<em>${a || b}</em>`)
      .replace(/~~(.+?)~~/g, "<del>$1</del>");
  }

  const listItem = (raw) => {
    const text = raw.replace(/^\s*([-*+]|\d+\.)\s+/, "");
    const task = text.match(/^\[([ xX]?)\]\s+(.*)$/); // [ ], [], [x], [X]
    if (!task) return `<li>${inline(text)}</li>`;

    const checked = task[1].toLowerCase() === "x" ? " checked" : "";
    return `<li class="task"><input type="checkbox" disabled${checked}> ${inline(task[2])}</li>`;
  };

  const isHold = (l) => /^\u0000\d+\u0000$/.test(l.trim());
  const isHeading = (l) => /^#{1,6}\s+/.test(l);
  const isHr = (l) => /^\s*([-*_])(\s*\1){2,}\s*$/.test(l);
  const isQuote = (l) => /^>/.test(l);
  const isItem = (l) => /^\s*([-*+]|\d+\.)\s+/.test(l);
  const startsBlock = (l) =>
    isHold(l) || isHeading(l) || isHr(l) || isQuote(l) || isItem(l);

  function blocks(text) {
    const lines = text.split("\n");
    const out = [];
    let i = 0;

    while (i < lines.length) {
      const line = lines[i];

      if (!line.trim()) {
        i++;
        continue;
      }

      if (isHold(line)) {
        out.push(line.trim());
        i++;
        continue;
      }

      if (isHeading(line)) {
        const [, hashes, content] = line.match(/^(#{1,6})\s+(.*?)\s*#*\s*$/);
        out.push(`<h${hashes.length}>${inline(content)}</h${hashes.length}>`);
        i++;
        continue;
      }

      if (isHr(line)) {
        out.push("<hr>");
        i++;
        continue;
      }

      if (isQuote(line)) {
        const inner = [];
        while (i < lines.length && isQuote(lines[i]))
          inner.push(lines[i++].replace(/^>\s?/, ""));
        out.push(`<blockquote>${blocks(inner.join("\n"))}</blockquote>`);
        continue;
      }

      if (isItem(line)) {
        const tag = /^\s*\d+\./.test(line) ? "ol" : "ul";
        const items = [];
        while (i < lines.length && isItem(lines[i])) {
          items.push(listItem(lines[i]));
          i++;
        }
        out.push(`<${tag}>${items.join("")}</${tag}>`);
        continue;
      }

      // Paragraph: gather lines until a blank line or another block starts
      const para = [];
      while (i < lines.length && lines[i].trim() && !startsBlock(lines[i]))
        para.push(lines[i++]);
      out.push(`<p>${inline(para.join(" "))}</p>`);
    }
    return out.join("\n");
  }

  md = md.replace(/\r\n?/g, "\n");

  // Pull out fenced code blocks first so their contents are never parsed as Markdown
  md = md.replace(/^```(\w*)[ \t]*\n([\s\S]*?)^```[ \t]*$/gm, (_, lang, code) =>
    hold(
      `<pre><code${lang ? ` class="language-${lang}"` : ""}>${escapeHtml(code.replace(/\n$/, ""))}</code></pre>`,
    ),
  );

  return blocks(md).replace(/\u0000(\d+)\u0000/g, (_, n) => stash[n]);
}
