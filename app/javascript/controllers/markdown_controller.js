import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "body", "suggestions", "toggle", "toc", "wheel", "arc"];
  static values = {
    pages: { type: Object, default: {} },
    files: { type: Object, default: {} },
  };

  connect() {
    this._suggestIndex = 0;
    this._suggestItems = [];
    this._trigger = null;
    this._outsideClick = (event) => {
      if (!this.hasSuggestionsTarget) return;
      if (this.element.contains(event.target)) return;
      this.hideSuggestions();
    };
    document.addEventListener("click", this._outsideClick);
    this.update();
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick);
    cancelAnimationFrame(this._scrollRaf);
    cancelAnimationFrame(this._spinRaf);
    this._spinRaf = null;
    clearTimeout(this._tocHideTimer);
  }

  update() {
    if (this.hasInputTarget && this.hasBodyTarget) {
      this.bodyTarget.innerHTML = markdownToHtml(this.inputTarget.value, this.pagesMap(), this.filesMap());
      this.hydrateCsvEmbeds();
    }
    this.refreshSuggestions();
    this.renderToc();
  }

  // Fill in ![[file.csv]] embed tables. markdownToHtml is synchronous, so
  // CSV bodies load here, after the preview HTML is in the DOM. Results
  // are cached per URL (shared across keystrokes); a detached table or a
  // failed fetch resolves to the same file card PDFs use.
  hydrateCsvEmbeds() {
    if (!this.hasBodyTarget) return;
    if (!this._csvCache) this._csvCache = new Map();
    for (const table of this.bodyTarget.querySelectorAll("table[data-csv-src]")) {
      const src = table.getAttribute("data-csv-src");
      const label = table.getAttribute("data-csv-label") || "CSV file";
      if (!src) continue;
      if (!this._csvCache.has(src)) {
        this._csvCache.set(src, fetch(src).then((res) => {
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          return res.text();
        }).then((text) => {
          const clipped = text.length > CSV_EMBED_MAX_BYTES;
          const parsed = parseCsvPreview(clipped ? text.slice(0, CSV_EMBED_MAX_BYTES) : text, CSV_EMBED_MAX_ROWS);
          return { ...parsed, truncated: parsed.truncated || clipped };
        }).catch(() => null));
      }
      this._csvCache.get(src).then((parsed) => {
        if (table.isConnected) fillCsvEmbed(table, parsed, src, label);
      });
    }
  }

  // ---------- Wikilink autocomplete ([[...) ----------

  pagesMap() {
    return this.hasPagesValue ? this.pagesValue || {} : {};
  }

  filesMap() {
    return this.hasFilesValue ? this.filesValue || {} : {};
  }

  currentTrigger() {
    if (!this.hasInputTarget) return null;
    const el = this.inputTarget;
    const caret = el.selectionStart ?? el.value.length;
    const before = el.value.slice(0, caret);
    const match = before.match(/\[\[([^\[\]\n|#]*)$/);
    if (!match) return null;
    return { query: match[1], start: caret - match[1].length - 2, caret };
  }

  refreshSuggestions() {
    if (!this.hasSuggestionsTarget || !this.hasInputTarget) return;
    const trigger = this.currentTrigger();
    if (!trigger) {
      this.hideSuggestions();
      return;
    }
    const q = trigger.query;
    const lowerQ = q.toLowerCase();
    // Embed context (![[...]]) suggests workspace files; plain [[...]]
    // suggests pages. The "!" stays put, so inserting [[name]] still yields
    // a valid ![[name]] embed.
    const map = trigger.start > 0 && this.inputTarget.value[trigger.start - 1] === "!"
      ? this.filesMap()
      : this.pagesMap();
    const bareOf = (key) => {
      const slash = key.lastIndexOf("/");
      return slash >= 0 ? key.slice(slash + 1) : key;
    };
    // Group keys by page (URL) so each file is suggested once. Map order
    // is oldest page first, so first-seen order stays oldest.
    const byUrl = new Map();
    for (const [key, url] of Object.entries(map)) {
      let group = byUrl.get(url);
      if (!group) {
        group = [];
        byUrl.set(url, group);
      }
      group.push(key);
    }
    // A file needs its folder path shown when any other file shares the
    // same page name (case-insensitively); otherwise the bare name is
    // enough. Counted across all files so a narrowed query can't hide the
    // ambiguity (e.g. "setup" matching only Setup/Install).
    const counts = new Map();
    for (const keys of byUrl.values()) {
      const seen = new Set(keys.map((key) => bareOf(key).toLowerCase()));
      for (const lower of seen) counts.set(lower, (counts.get(lower) || 0) + 1);
    }
    const labelFor = (keys) => {
      const ambiguous = keys.some((key) => counts.get(bareOf(key).toLowerCase()) > 1);
      if (!ambiguous) return keys.find((key) => !key.includes("/")) || keys[0];
      const qualified = keys.filter((key) => key.includes("/")).sort((a, b) => a.length - b.length);
      return qualified[0] || keys[0];
    };
    const files = [];
    for (const keys of byUrl.values()) {
      const matching = keys.filter((key) => key.toLowerCase().includes(lowerQ));
      if (matching.length === 0) continue;
      files.push({
        label: labelFor(keys),
        exact: matching.some((key) => key.includes(q)) ? 0 : 1,
      });
    }
    if (files.length === 0) {
      this.hideSuggestions();
      return;
    }
    // Caps-sensitive first: exact-case substring matches rank above
    // case-insensitive ones. Stable sort keeps oldest-first order within
    // each group.
    files.sort((a, b) => a.exact - b.exact);
    this._trigger = trigger;
    this._suggestItems = files.slice(0, 8).map((file) => file.label);
    this._suggestIndex = Math.min(this._suggestIndex, this._suggestItems.length - 1);
    if (this._suggestIndex < 0) this._suggestIndex = 0;
    this.renderSuggestions();
  }

  renderSuggestions() {
    const box = this.suggestionsTarget;
    box.innerHTML = "";
    this._suggestItems.forEach((name, index) => {
      const option = document.createElement("button");
      option.type = "button";
      option.className = "wikilink-suggest__option";
      if (index === this._suggestIndex) option.classList.add("wikilink-suggest__option--active");
      option.setAttribute("role", "option");
      option.setAttribute("aria-selected", index === this._suggestIndex ? "true" : "false");
      option.dataset.index = index;
      option.textContent = name;
      // mousedown fires before textarea blur, so the caret context survives.
      option.addEventListener("mousedown", (event) => {
        event.preventDefault();
        this.chooseSuggestion(index);
      });
      box.appendChild(option);
    });
    box.hidden = false;
  }

  hideSuggestions() {
    this._suggestItems = [];
    this._suggestIndex = 0;
    this._trigger = null;
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.innerHTML = "";
      this.suggestionsTarget.hidden = true;
    }
  }

  chooseSuggestion(index) {
    const name = this._suggestItems[index];
    const trigger = this._trigger || this.currentTrigger();
    if (!name || !trigger || !this.hasInputTarget) {
      this.hideSuggestions();
      return;
    }
    const el = this.inputTarget;
    const caret = el.selectionStart ?? trigger.caret;
    const insert = `[[${name}]]`;
    el.value = el.value.slice(0, trigger.start) + insert + el.value.slice(caret);
    const nextCaret = trigger.start + insert.length;
    el.focus();
    el.setSelectionRange(nextCaret, nextCaret);
    this.hideSuggestions();
    el.dispatchEvent(new Event("input", { bubbles: true }));
    this.update();
  }

  onKeyDown(event) {
    if (event.key === "Escape" && this.hasTocTarget && !this.tocTarget.hidden) {
      event.preventDefault();
      this.closeToc();
      return;
    }
    if (!this.hasSuggestionsTarget || this.suggestionsTarget.hidden) return;
    if (event.key === "ArrowDown") {
      event.preventDefault();
      this._suggestIndex = (this._suggestIndex + 1) % this._suggestItems.length;
      this.renderSuggestions();
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      this._suggestIndex =
        (this._suggestIndex - 1 + this._suggestItems.length) % this._suggestItems.length;
      this.renderSuggestions();
    } else if (event.key === "Enter" || event.key === "Tab") {
      event.preventDefault();
      this.chooseSuggestion(this._suggestIndex);
    } else if (event.key === "Escape") {
      event.preventDefault();
      this.hideSuggestions();
    }
  }

  // ---------- Headings nav (TOC overlay) ----------

  // Half-wheel arc geometry (degrees): headings ride a semicircle opening
  // left, the active one pinned at the pointer. Bounded: position clamps to
  // [0, N-1], so the wheel never wraps around.
  static get tocStep() { return 26; }
  static get tocWindow() { return 2.8; }

  renderToc() {
    if (!this.hasArcTarget || !this.hasBodyTarget) return;
    const headings = [...this.bodyTarget.querySelectorAll("h1, h2, h3, h4, h5, h6")];
    // Belt and braces: headings from inline HTML may carry no id, so mint
    // one from their text before building entries.
    const seen = {};
    for (const heading of headings) {
      if (!heading.id) {
        const slug = slugifyHeading(heading.textContent || "");
        const count = seen[slug] || 0;
        seen[slug] = count + 1;
        heading.id = count === 0 ? slug : `${slug}-${count}`;
      }
    }
    const arc = this.arcTarget;
    arc.innerHTML = "";
    this._tocHeadings = headings.map((heading) => ({ id: heading.id, text: heading.textContent }));
    this._tocHeadings.forEach((entry, index) => {
      const item = document.createElement("button");
      item.type = "button";
      item.className = "toc-wheel__item";
      item.textContent = entry.text;
      item.title = entry.text;
      item.setAttribute("aria-label", entry.text);
      item.dataset.index = index;
      item.addEventListener("click", () => this.jumpToTocIndex(index));
      arc.appendChild(item);
    });
    if (this.hasToggleTarget) this.toggleTarget.hidden = headings.length === 0;
    if (headings.length === 0) {
      this._tocHeadings = [];
      this.closeToc();
      return;
    }
    this._tocPos = this.clampToc(this._tocPos || 0);
    this._tocVel = 0;
    this.setActiveToc(Math.round(this._tocPos));
    this.paintArc();
  }

  clampToc(pos) {
    const n = this._tocHeadings.length;
    if (n === 0) return 0;
    return Math.max(0, Math.min(n - 1, pos));
  }

  setActiveToc(index) {
    this._tocActive = index;
    if (!this.hasArcTarget) return;
    [...this.arcTarget.children].forEach((item, i) =>
      item.classList.toggle("toc-wheel__item--active", i === index)
    );
  }

  // Pivot (px, viewport coords) the arc swings around: right-middle of the
  // wheel, so headings curve out into the preview.
  tocPivot() {
    const rect = this.wheelTarget.getBoundingClientRect();
    const rem = parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;
    return {
      x: rect.right - 1 * rem,
      y: rect.top + rect.height / 2,
      radius: 5 * rem,
    };
  }

  paintArc() {
    if (!this.hasArcTarget || !this.hasWheelTarget) return;
    const n = this._tocHeadings.length;
    if (n === 0) return;
    const { x: px, y: py, radius: radius } = this.tocPivot();
    const wheelRect = this.wheelTarget.getBoundingClientRect();
    const step = this.constructor.tocStep * (Math.PI / 180);
    const items = this.arcTarget.children;
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const offset = i - this._tocPos;
      if (Math.abs(offset) > this.constructor.tocWindow + 0.5) {
        item.style.visibility = "hidden";
        continue;
      }
      item.style.visibility = "visible";
      const x = px - radius * Math.cos(offset * step) - wheelRect.left;
      const y = py + radius * Math.sin(offset * step) - wheelRect.top;
      const closeness = Math.max(0, 1 - Math.abs(offset) / (this.constructor.tocWindow + 0.5));
      const scale = 0.85 + closeness * 0.25;
      item.style.left = `${x}px`;
      item.style.top = `${y}px`;
      item.style.transform = `translate(-50%, -50%) scale(${scale})`;
      item.style.opacity = `${0.45 + closeness * 0.55}`;
    }
  }

  // Detent click: brief pop when the wheel settles onto a heading.
  pulseToc() {
    if (!this.hasArcTarget) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const item = this.arcTarget.children[this._tocActive];
    if (!item) return;
    item.classList.remove("toc-wheel__item--tick");
    void item.offsetWidth;
    item.classList.add("toc-wheel__item--tick");
  }

  toggleToc() {
    if (!this.hasTocTarget) return;
    if (this.tocTarget.hidden || !this.tocTarget.classList.contains("toc-panel--open")) {
      this.openToc();
    } else {
      this.closeToc();
    }
  }

  openToc() {
    if (!this.hasTocTarget) return;
    clearTimeout(this._tocHideTimer);
    this.tocTarget.hidden = false;
    // Reflow so the slide-in transition runs from the translated state.
    void this.tocTarget.offsetWidth;
    this.tocTarget.classList.add("toc-panel--open");
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "true");
    this.paintArc();
    if (!this._spinRaf) {
      this._spinRaf = requestAnimationFrame(() => this.spinLoop());
    }
  }

  closeToc() {
    if (!this.hasTocTarget) return;
    this.tocTarget.classList.remove("toc-panel--open");
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false");
    // Keep the panel laid out while it slides out, then hide it.
    clearTimeout(this._tocHideTimer);
    this._tocHideTimer = setTimeout(() => {
      if (this.hasTocTarget) this.tocTarget.hidden = true;
    }, 250);
  }

  onTocKeyDown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      this.closeToc();
      if (this.hasToggleTarget) this.toggleTarget.focus();
      return;
    }
    const nudge = event.key === "ArrowDown" || event.key === "ArrowRight" ? 1
      : event.key === "ArrowUp" || event.key === "ArrowLeft" ? -1 : 0;
    if (nudge !== 0) {
      event.preventDefault();
      this.nudgeToc(nudge);
    } else if (event.key === "Enter") {
      event.preventDefault();
      this.jumpActive();
    }
  }

  nudgeToc(direction) {
    if (this._tocHeadings.length === 0) return;
    this._tocPos = this.clampToc(Math.round(this._tocPos) + direction);
    this._tocVel = 0;
    this.setActiveToc(Math.round(this._tocPos));
    this.paintArc();
  }

  // Rolling the wheel over the dial moves along the headings. Position is
  // clamped, so the wheel stops at the first/last heading (no wrap).
  onWheelSpin(event) {
    event.preventDefault();
    if (!this.hasTocTarget || this.tocTarget.hidden) return;
    if (this._tocHeadings.length === 0) return;
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const unit = event.deltaMode === 1 ? 16 : 1;
    const step = (event.deltaY + event.deltaX) * unit * 0.004;
    if (reduced) {
      this._tocPos = this.clampToc(Math.round(this._tocPos + step * 4));
      this._tocVel = 0;
      this.setActiveToc(Math.round(this._tocPos));
      this.paintArc();
      return;
    }
    this._tocPos = this.clampToc(this._tocPos + step);
    this._tocVel = 0.6 * step + 0.4 * this._tocVel;
    if (this._tocPos === 0 || this._tocPos === this._tocHeadings.length - 1) this._tocVel = 0;
  }

  // Grab the dial and turn it by hand. Pointer capture only kicks in once
  // the pointer actually travels, so plain clicks still reach the headings.
  onWheelGrab(event) {
    if (!this.hasWheelTarget) return;
    this._dragging = true;
    this._captured = false;
    this._dragMoved = 0;
    this._tocVel = 0;
    this._lastPointerAngle = this.pivotAngle(event);
    this._lastMoveTime = performance.now();
  }

  onWheelDrag(event) {
    if (!this._dragging || !this.hasWheelTarget) return;
    const angle = this.pivotAngle(event);
    let delta = angle - this._lastPointerAngle;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    // Clockwise around the pivot rolls down the arc (later headings).
    const step = -delta / this.constructor.tocStep;
    this._dragMoved += Math.abs(delta);
    if (!this._captured && this._dragMoved > 6) {
      try { this.wheelTarget.setPointerCapture(event.pointerId); } catch { /* already released */ }
      this._captured = true;
    }
    this._tocPos = this.clampToc(this._tocPos + step);
    const now = performance.now();
    const dt = Math.max(now - this._lastMoveTime, 1);
    this._tocVel = 0.7 * ((step / dt) * 16.7) + 0.3 * this._tocVel;
    if (this._tocPos === 0 || this._tocPos === this._tocHeadings.length - 1) this._tocVel = 0;
    this._lastPointerAngle = angle;
    this._lastMoveTime = now;
    this.paintArc();
    const index = Math.round(this._tocPos);
    if (index !== this._tocActive) this.setActiveToc(index);
  }

  onWheelRelease() {
    this._dragging = false;
    this._captured = false;
  }

  // Pointer angle (degrees) around the arc pivot, for hand-turning.
  pivotAngle(event) {
    const { x: px, y: py } = this.tocPivot();
    return (Math.atan2(event.clientY - py, event.clientX - px) * 180) / Math.PI;
  }

  // Physics loop: free roll with friction at speed, then a slow ease onto
  // the nearest heading (the detent click) once the wheel calms down.
  // Bounded: the position clamps, so the ends are hard stops.
  spinLoop() {
    this._spinRaf = null;
    if (!this.hasTocTarget || this.tocTarget.hidden) return;
    const n = this._tocHeadings.length;
    if (n > 0) {
      const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      this._tocPos = this.clampToc(this._tocPos + this._tocVel);
      this._tocVel *= 0.9;
      if (this._tocPos === 0 || this._tocPos === n - 1) this._tocVel = 0;
      if (!this._dragging && Math.abs(this._tocVel) < 0.06) {
        const nearest = Math.round(this._tocPos);
        const ease = reduced ? 1 : 0.2;
        this._tocPos += (nearest - this._tocPos) * ease;
        if (Math.abs(nearest - this._tocPos) < 0.004) {
          this._tocPos = nearest;
          this._tocVel = 0;
        }
        if (nearest !== this._tocActive) {
          this.setActiveToc(nearest);
          this.pulseToc();
        }
      } else {
        const index = Math.round(this._tocPos);
        if (index !== this._tocActive) this.setActiveToc(index);
      }
      this.paintArc();
    }
    this._spinRaf = requestAnimationFrame(() => this.spinLoop());
  }

  jumpActive() {
    this.jumpToTocIndex(this._tocActive || 0);
  }

  jumpToTocIndex(index) {
    // A drag that travels is a spin, not a click.
    if (this._dragMoved > 6) return;
    const entry = this._tocHeadings[index];
    const heading = entry && this.hasBodyTarget
      ? this.bodyTarget.querySelector(`#${CSS.escape(entry.id)}`)
      : null;
    this.closeToc();
    if (heading) this.smoothScrollTo(heading, 400);
  }

  // Animated scroll (duration in ms) to a preview heading. Native
  // scrollIntoView has no duration control, so this drives the nearest
  // scrollable ancestor (else the window) with requestAnimationFrame.
  smoothScrollTo(el, duration) {
    cancelAnimationFrame(this._scrollRaf);
    let scroller = null;
    let node = el.parentElement;
    while (node && node !== document.documentElement) {
      if (node.scrollHeight > node.clientHeight + 1) { scroller = node; break; }
      node = node.parentElement;
    }
    const offset = 12;
    const target = scroller
      ? scroller.scrollTop + (el.getBoundingClientRect().top - scroller.getBoundingClientRect().top) - offset
      : window.scrollY + el.getBoundingClientRect().top - offset;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      if (scroller) scroller.scrollTop = target;
      else window.scrollTo(0, target);
      return;
    }
    const start = scroller ? scroller.scrollTop : window.scrollY;
    const delta = target - start;
    const startedAt = performance.now();
    const step = (now) => {
      const t = Math.min((now - startedAt) / duration, 1);
      const eased = t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
      if (scroller) scroller.scrollTop = start + delta * eased;
      else window.scrollTo(0, start + delta * eased);
      if (t < 1) this._scrollRaf = requestAnimationFrame(step);
    };
    this._scrollRaf = requestAnimationFrame(step);
  }
}

// Anchor slugs for headings. Output is sanitizer-safe ([a-z0-9-] only).
function slugifyHeading(raw) {
  let slug = raw
    .toLowerCase()
    .replace(/[`*_~\[\]()#!|]/g, "")
    .replace(/[^a-z0-9\s_-]/g, "")
    .trim()
    .replace(/[\s_]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  return slug || "heading";
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
  h1: ["id"],
  h2: ["id"],
  h3: ["id"],
  h4: ["id"],
  h5: ["id"],
  h6: ["id"],
};
const STYLE_PROPS =
  /^(color|background(-color)?|font(-size|-weight|-style|-family)?|text-(decoration|align|transform|shadow)|letter-spacing|line-height|margin(-[a-z]+)?|padding(-[a-z]+)?|border(-[a-z-]+)?|width|max-width|height|max-height|opacity|white-space|vertical-align)$/;
const BAD_STYLE_VALUE = /url\s*\(|image-set|expression|@import|javascript:|\\/i;

const isSafeUrl = (u) => {
  const v = u.replace(/[\u0000-\u0020\u007f-\u009f]/g, "");
  // Protocol-relative URLs inherit the page scheme and hand the fetch to a
  // third party (tracking pixel / mixed-content vector), so they go with the
  // dangerous schemes. Plain relative paths stay allowed.
  if (v.startsWith("//")) return false;
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
        // data-csv-* hooks on CSV embed tables are inert (never interpreted
        // by the browser) and only read back by hydrateCsvEmbeds below.
        const isCsvHook = tag === "table" && name.startsWith("data-csv-");
        if (!isCsvHook && !GLOBAL_ATTRS.has(name) && !(TAG_ATTRS[tag] || []).includes(name)) {
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

// ---------- CSV embeds (![[file.csv]]) ----------
const CSV_EMBED_MAX_ROWS = 10;
const CSV_EMBED_MAX_BYTES = 524288;

// Minimal CSV parser for previews: commas, quotes ("" escapes), CRLF and
// quoted newlines. Returns { header, body, truncated }; lenient by design
// (a clipped or quirky file still shows something rather than erroring).
function parseCsvPreview(text, maxDataRows) {
  const rows = [];
  let row = [], field = "", inQuotes = false;
  const endField = () => { row.push(field); field = ""; };
  const endRow = () => { rows.push(row); row = []; };
  for (let i = 0; i < text.length && rows.length <= maxDataRows + 1; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i++; }
        else inQuotes = false;
      } else field += c;
    } else if (c === '"') inQuotes = true;
    else if (c === ",") endField();
    else if (c === "\r") { /* CRLF pairs close on \n */ }
    else if (c === "\n") {
      endField();
      if (row.length > 1 || row[0] !== "") endRow();
      else row = [];
    } else field += c;
  }
  if (field !== "" || row.length > 0) { endField(); endRow(); }
  return {
    header: rows[0] ?? [],
    body: rows.slice(1, 1 + maxDataRows),
    truncated: rows.length > maxDataRows + 1,
  };
}

// Fill a CSV placeholder table in place (built with DOM APIs, so cell
// content needs no extra escaping). A null parse degrades to the PDF-style
// file card, which also handles cross-origin blob hosts that block fetch.
function fillCsvEmbed(table, parsed, src, label) {
  const doc = table.ownerDocument;
  if (!parsed) {
    const link = doc.createElement("a");
    link.className = "embed embed--file";
    link.href = src;
    link.target = "_blank";
    link.title = label;
    link.textContent = label;
    table.replaceWith(link);
    return;
  }
  const width = Math.max(parsed.header.length, ...parsed.body.map((r) => r.length), 1);
  const pad = (cells) => cells.concat(Array(Math.max(0, width - cells.length)).fill(""));
  const thead = doc.createElement("thead");
  const headRow = doc.createElement("tr");
  for (const text of pad(parsed.header)) {
    const th = doc.createElement("th");
    th.setAttribute("scope", "col");
    th.textContent = text;
    headRow.appendChild(th);
  }
  thead.appendChild(headRow);
  const tbody = doc.createElement("tbody");
  if (parsed.header.length === 0 && parsed.body.length === 0) {
    const tr = doc.createElement("tr");
    const td = doc.createElement("td");
    td.textContent = "Empty CSV file.";
    tr.appendChild(td);
    tbody.appendChild(tr);
  }
  for (const cells of parsed.body) {
    const tr = doc.createElement("tr");
    for (const text of pad(cells)) {
      const td = doc.createElement("td");
      td.textContent = text;
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }
  if (parsed.truncated) {
    const tr = doc.createElement("tr");
    const td = doc.createElement("td");
    td.setAttribute("colspan", String(width));
    td.textContent = `Showing the first ${parsed.body.length} rows. `;
    const link = doc.createElement("a");
    link.href = src;
    link.target = "_blank";
    link.textContent = "Open the full file";
    td.appendChild(link);
    tr.appendChild(td);
    tbody.appendChild(tr);
  }
  table.replaceChildren(thead, tbody);
}

// ---------- Converter ----------
function markdownToHtml(md, pages = {}, files = {}) {
  const pageMap = pages || {};
  const fileMap = files || {};
  // Case-insensitive fallback indexes: the server emits oldest first, so
  // first-wins keeps the oldest entry per lowercased form.
  const lowerMap = {};
  for (const key of Object.keys(pageMap)) {
    const lower = key.toLowerCase();
    if (!(lower in lowerMap)) lowerMap[lower] = pageMap[key];
  }
  const fileLowerMap = {};
  for (const key of Object.keys(fileMap)) {
    const lower = key.toLowerCase();
    if (!(lower in fileLowerMap)) fileLowerMap[lower] = fileMap[key];
  }
  const stash = [];
  const hold = (html) => `\u0000${stash.push(html) - 1}\u0000`;
  const escapeHtml = (s) =>
    s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  const escapeText = (s) =>
    s.replace(/&(?!#?\w+;)/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  const safeUrl = (u) => (/^\s*(\/\/|(javascript|data|vbscript):)/i.test(u) ? "#" : u);

  // Anchor ids for headings (read back from the DOM to build the TOC).
  // Slugs are sanitizer-safe ([a-z0-9-] only) and deduplicated per render.
  const slugCounts = {};
  const headingId = (raw) => {
    const slug = slugifyHeading(raw);
    const seen = slugCounts[slug] || 0;
    slugCounts[slug] = seen + 1;
    return seen === 0 ? slug : `${slug}-${seen}`;
  };

  // Raw-HTML headings (<h1>test</h1>) bypass the markdown heading path, so
  // give them ids here. Existing ids are left alone.
  const addHeadingIds = (html) =>
    html.replace(/<h([1-6])((?:\s[^<>]*)?)>([\s\S]*?)<\/h\1\s*>/gi, (tag, level, attrs, inner) => {
      if (/\bid\s*=/.test(attrs)) return tag;
      const text = inner.replace(/<[^<>]*>/g, "");
      return `<h${level} id="${headingId(text)}"${attrs}>${inner}</h${level}>`;
    });

  function inline(text) {
    text = text.replace(/`([^`]+)`/g, (_, c) => hold(`<code>${escapeHtml(c)}</code>`));

    text = text.replace(/<\/?([a-zA-Z][a-zA-Z0-9]*)(?:\s[^<>]*)?\/?>/g, (m, name) =>
      ALLOWED_TAGS.has(name.toLowerCase()) ? hold(m) : m
    );

    text = escapeText(text);
    // Obsidian-style embeds (![[file]]). Runs before plain wikilinks since
    // every embed contains a [[...]] pair. Image uploads become images;
    // PDFs become a file card that opens in a new tab (object/embed/iframe
    // are sanitizer-dropped, and a PDF in an <img> renders broken).
    // Missing files reuse the missing-link style so they stay clickable.
    text = text.replace(
      /!\[\[([^\[\]\n|#]+)(?:#[^\[\]\n|]*)?(?:\|([^\[\]\n]*))?\]\]/g,
      (_, target, alias) => {
        const rawKey = target.trim();
        const raw = (alias !== undefined ? alias.trim() || target.trim() : target.trim());
        const label = raw.split("/").pop().trim() || raw;
        const url = fileMap[rawKey] ?? fileLowerMap[rawKey.toLowerCase()];
        if (url) {
          if (/\.pdf$/i.test(rawKey)) {
            return `<a class="embed embed--file" href="${safeUrl(url)}" target="_blank" title="${label}">${label}</a>`;
          }
          // CSVs hydrate into a compact table after render (see
          // hydrateCsvEmbeds). The placeholder carries inert data-csv-*
          // hooks, which the sanitizer below explicitly allows on tables.
          if (/\.csv$/i.test(rawKey)) {
            return `<table class="embed embed--table" data-csv-src="${safeUrl(url)}" data-csv-label="${label}"><tbody><tr><td>Loading preview…</td></tr></tbody></table>`;
          }
          return `<img class="embed" src="${safeUrl(url)}" alt="${label}">`;
        }
        return `<a class="wikilink wikilink--missing" href="#" title="File not found">${label}</a>`;
      }
    );
    // Obsidian-style wikilinks. Runs on escaped text after code spans are
    // stashed (so `[[x]]` and fenced blocks stay literal) and before the
    // [text](url) rule so the brackets don't interact.
    text = text.replace(
      /\[\[([^\[\]\n|#]+)(?:#[^\[\]\n|]*)?(?:\|([^\[\]\n]*))?\]\]/g,
      (_, target, alias) => {
        const rawKey = target.trim();
        // Exact case first, oldest case-insensitive match as fallback so
        // old links keep working when no exact-case spelling exists.
        // No alias: show just the page name (last path segment) so
        // [[Guides/Install]] renders as "Install" but still resolves.
        const raw = (alias !== undefined ? alias.trim() || target.trim() : target.trim());
        const label = alias !== undefined ? raw : raw.split("/").pop().trim() || raw;
        const url = pageMap[rawKey] ?? lowerMap[rawKey.toLowerCase()];
        if (url) {
          return `<a class="wikilink" href="${safeUrl(url)}">${label}</a>`;
        }
        return `<a class="wikilink wikilink--missing" href="#" title="Page not found">${label}</a>`;
      }
    );
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
        out.push(addHeadingIds(html.join("\n")));
        continue;
      }

      if (isHeading(line)) {
        const [, hashes, content] = line.match(/^(#{1,6})\s+(.*?)\s*#*\s*$/);
        out.push(`<h${hashes.length} id="${headingId(content)}">${inline(content)}</h${hashes.length}>`);
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