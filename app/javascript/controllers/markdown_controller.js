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

// ---------- Sanitizer (browser only: uses DOMParser) ----------
const ALLOWED_TAGS = new Set(
  ("a b i em strong del s u ins mark small sub sup code pre kbd br hr p div span blockquote " +
   "h1 h2 h3 h4 h5 h6 ul ol li dl dt dd table thead tbody tfoot tr th td caption img input " +
   "details summary figure figcaption center").split(" ")
);
const DROP_TAGS = new Set([
  "script", "style", "iframe", "object", "embed", "link", "meta", "base", "form",
  "textarea", "select", "button", "svg", "math", "noscript", "template", "title",
]);
const GLOBAL_ATTRS = new Set(["class", "title", "style"]);
const TAG_ATTRS = {
  a: ["href", "target", "rel"],
  img: ["src", "alt", "width", "height"],
  input: ["type", "checked", "disabled"],
  td: ["colspan", "rowspan"],
  th: ["colspan", "rowspan"],
  ol: ["start"],
  details: ["open"],
};
const STYLE_PROPS =
  /^(color|background(-color)?|font(-size|-weight|-style|-family)?|text-(decoration|align|transform|shadow)|letter-spacing|line-height|margin(-[a-z]+)?|padding(-[a-z]+)?|border(-[a-z-]+)?|width|max-width|height|max-height|opacity|white-space|vertical-align)$/;
const BAD_STYLE_VALUE = /url\s*\(|image-set|expression|@import|javascript:|\\/i;

const isSafeUrl = (u) => {
  const v = u.replace(/[\u0000-\u0020\u007f-\u009f]/g, "");
  return !/^[a-z][a-z0-9+.-]*:/i.test(v) || /^(https?|mailto|tel):/i.test(v);
};

const cleanStyle = (css) =>
  css
    .split(";")
    .map((d) => d.trim())
    .filter((d) => {
      const i = d.indexOf(":");
      if (i < 1) return false;
      const prop = d.slice(0, i).trim().toLowerCase();
      return STYLE_PROPS.test(prop) && !BAD_STYLE_VALUE.test(d.slice(i + 1));
    })
    .join("; ");

function sanitizeHtml(html) {
  const doc = new DOMParser().parseFromString(html, "text/html"); // inert: nothing executes

  const walk = (parent) => {
    for (const el of [...parent.childNodes]) {
      if (el.nodeType === 8) { el.remove(); continue; }   // comments
      if (el.nodeType !== 1) continue;                     // keep text nodes

      const tag = el.tagName.toLowerCase();
      if (DROP_TAGS.has(tag)) { el.remove(); continue; }
      if (!ALLOWED_TAGS.has(tag)) { walk(el); el.replaceWith(...el.childNodes); continue; } // unwrap

      for (const attr of [...el.attributes]) {
        const name = attr.name.toLowerCase();
        if (!GLOBAL_ATTRS.has(name) && !(TAG_ATTRS[tag] || []).includes(name)) {
          el.removeAttribute(attr.name);
        } else if ((name === "href" || name === "src") && !isSafeUrl(attr.value)) {
          el.removeAttribute(attr.name);
        } else if (name === "style") {
          const s = cleanStyle(attr.value);
          s ? el.setAttribute("style", s) : el.removeAttribute("style");
        }
      }

      if (tag === "a" && el.getAttribute("target") === "_blank") {
        el.setAttribute("rel", "noopener noreferrer");
      }
      if (tag === "input") {
        if (el.getAttribute("type") !== "checkbox") { el.remove(); continue; }
        el.setAttribute("disabled", "");
      }
      walk(el);
    }
  };

  walk(doc.body);
  return doc.body.innerHTML;
}

// ---------- Converter ----------
function markdownToHtml(md) {
  const stash = [];
  const hold = (html) => `\u0000${stash.push(html) - 1}\u0000`;
  const escapeHtml = (s) =>
    s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  const escapeText = (s) =>
    s.replace(/&(?!#?\w+;)/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  const safeUrl = (u) => (/^\s*(javascript|data|vbscript):/i.test(u) ? "#" : u);

  function inline(text) {
    text = text.replace(/`([^`]+)`/g, (_, c) => hold(`<code>${escapeHtml(c)}</code>`));

    text = text.replace(/<\/?([a-zA-Z][a-zA-Z0-9]*)(?:\s[^<>]*)?\/?>/g, (m, name) =>
      ALLOWED_TAGS.has(name.toLowerCase()) ? hold(m) : m
    );

    text = escapeText(text);
    return text
      .replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (_, alt, src) => `<img src="${safeUrl(src)}" alt="${alt}">`)
      .replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_, t, href) => `<a href="${safeUrl(href)}">${t}</a>`)
      .replace(/\*\*(.+?)\*\*|__(.+?)__/g, (_, a, b) => `<strong>${a || b}</strong>`)
      .replace(/\*(.+?)\*|\b_(.+?)_\b/g, (_, a, b) => `<em>${a || b}</em>`)
      .replace(/~~(.+?)~~/g, "<del>$1</del>");
  }

  const listItem = (raw) => {
    const text = raw.replace(/^\s*([-*+]|\d+\.)\s+/, "");
    const task = text.match(/^\[([ xX]?)\]\s+(.*)$/);
    if (!task) return `<li>${inline(text)}</li>`;
    const checked = task[1].toLowerCase() === "x" ? " checked" : "";
    return `<li class="task"><input type="checkbox" disabled${checked}> ${inline(task[2])}</li>`;
  };

  const HTML_BLOCK =
    /^ {0,3}<\/?(?:address|article|aside|blockquote|details|div|dl|dt|dd|figure|figcaption|footer|header|h[1-6]|hr|li|main|nav|ol|p|pre|section|summary|table|thead|tbody|tfoot|tr|th|td|caption|ul|center)(?:\s|\/?>|$)/i;

  const isHold = (l) => /^\u0000\d+\u0000$/.test(l.trim());
  const isHtmlBlock = (l) => HTML_BLOCK.test(l);
  const isHeading = (l) => /^#{1,6}\s+/.test(l);
  const isHr = (l) => /^\s*([-*_])(\s*\1){2,}\s*$/.test(l);
  // Blockquote marker: up to 3 leading spaces (4+ is indented code, not a quote)
  const isQuote = (l) => /^ {0,3}>/.test(l);
  const stripQuote = (l) => l.replace(/^ {0,3}>[ \t]?/, "");
  const isFenceStart = (l) => /^ {0,3}```/.test(l);
  const isItem = (l) => /^\s*([-*+]|\d+\.)\s+/.test(l);
  const startsBlock = (l) =>
    isHold(l) || isHtmlBlock(l) || isHeading(l) || isHr(l) || isQuote(l) || isItem(l) || isFenceStart(l);

  const isParaText = (l) =>
    l.trim() && !isHold(l) && !isHtmlBlock(l) && !isHeading(l) && !isHr(l) && !isQuote(l) && !isItem(l) && !isFenceStart(l);

  function blocksLines(lines, quotedFlags) {
    const out = [];
    let i = 0;

    while (i < lines.length) {
      const line = lines[i];

      if (!line.trim()) { i++; continue; }
      if (isHold(line)) { out.push(line.trim()); i++; continue; }

      if (isHtmlBlock(line)) {
        const html = [];
        while (i < lines.length && lines[i].trim()) html.push(lines[i++]);
        out.push(html.join("\n"));
        continue;
      }

      if (isHeading(line)) {
        const [, hashes, content] = line.match(/^(#{1,6})\s+(.*?)\s*#*\s*$/);
        out.push(`<h${hashes.length}>${inline(content)}</h${hashes.length}>`);
        i++; continue;
      }

      if (isHr(line)) { out.push("<hr>"); i++; continue; }

      if (isFenceStart(line)) {
        const fence = line.match(/^ {0,3}```(\w*)[ \t]*$/);
        // Unclosed fence: treat opening as paragraph text
        if (!fence) {
          const para = [];
          while (i < lines.length && lines[i].trim() && !startsBlock(lines[i])) para.push(lines[i++]);
          // If nothing consumed (should not happen), avoid infinite loop
          if (!para.length) { out.push(`<p>${inline(line)}</p>`); i++; }
          else out.push(`<p>${inline(para.join(" "))}</p>`);
          continue;
        }
        const lang = fence[1];
        const codeLines = [];
        i++;
        while (i < lines.length && !/^ {0,3}```[ \t]*$/.test(lines[i])) codeLines.push(lines[i++]);
        if (i < lines.length) i++; // consume closing fence
        out.push(hold(`<pre><code${lang ? ` class="language-${lang}"` : ""}>${escapeHtml(codeLines.join("\n"))}</code></pre>`));
        continue;
      }

      // Blockquote: supports nesting, lazy continuation lines, blank lines,
      // and fenced code / lists / headings inside via recursion.
      if (isQuote(line)) {
        const inner = [];
        const innerQuoted = [];
        while (i < lines.length) {
          const cur = lines[i];
          if (isQuote(cur)) {
            inner.push(stripQuote(cur));
            innerQuoted.push(true);
            i++;
            continue;
          }
          if (!cur.trim()) {
            // Blank line belongs to the quote only if more quoted content follows.
            let j = i + 1;
            while (j < lines.length && !lines[j].trim()) j++;
            if (j < lines.length && isQuote(lines[j])) {
              while (i < j) { inner.push(""); innerQuoted.push(true); i++; }
              continue;
            }
            break;
          }
          // Lazy continuation: a plain paragraph line following quoted
          // paragraph text belongs to the quote (CommonMark). A bare line may
          // also follow a nested `>` marker so it can be passed down to the
          // nested quote, but never after a list/heading/code block.
          // Inside a quote, only consume lines that were lazy at the parent
          // level (flag false) so outer-quoted siblings aren't swallowed by
          // a nested quote.
          if (!startsBlock(cur) && inner.length) {
            const prev = inner[inner.length - 1];
            if ((isParaText(prev) || isQuote(prev)) && (quotedFlags == null || quotedFlags[i] === false)) {
              inner.push(cur);
              innerQuoted.push(false);
              i++;
              continue;
            }
          }
          break;
        }
        const rendered = blocksLines(inner, innerQuoted);
        if (rendered.trim()) out.push(`<blockquote>${rendered}</blockquote>`);
        continue;
      }

      if (isItem(line)) {
        const tag = /^\s*\d+\./.test(line) ? "ol" : "ul";
        const items = [];
        while (i < lines.length && isItem(lines[i])) items.push(listItem(lines[i++]));
        out.push(`<${tag}>${items.join("")}</${tag}>`);
        continue;
      }

      const para = [];
      while (i < lines.length && lines[i].trim() && !startsBlock(lines[i])) para.push(lines[i++]);
      out.push(`<p>${inline(para.join(" "))}</p>`);
    }
    return out.join("\n");
  }

  function blocks(text) {
    return blocksLines(text.split("\n"), null);
  }

  md = md.replace(/\r\n?/g, "\n");

  md = md.replace(/^```(\w*)[ \t]*\n([\s\S]*?)^```[ \t]*$/gm, (_, lang, code) =>
    hold(`<pre><code${lang ? ` class="language-${lang}"` : ""}>${escapeHtml(code.replace(/\n$/, ""))}</code></pre>`)
  );

  const html = blocks(md).replace(/\u0000(\d+)\u0000/g, (_, n) => stash[n]);
  return sanitizeHtml(html);
}