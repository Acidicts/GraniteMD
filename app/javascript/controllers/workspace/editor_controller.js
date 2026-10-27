import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["textarea", "status", "highlight"];
  static values = {
    endpoint: String,
    pageId: Number,
    paramKey: { type: String, default: "page" },
  };

  connect() {
    this._lastSaved = this.hasTextareaTarget ? this.textareaTarget.value : "";
    this.renderHighlight();
    this.updateLines();
  }

  disconnect() {
    this.cancelScheduledRender();
    // Flush a pending debounced save so quick file-switching doesn't lose edits.
    clearTimeout(this._fileChangeTimer);
    this._fileChangeTimer = null;
    if (this.hasTextareaTarget && this.textareaTarget.value !== this._lastSaved) {
      this.saveFile({ keepalive: true });
    }
    if (this._saveRequest) this._saveRequest.abort();
  }

  fileChange() {
    this.scheduleRender();
    clearTimeout(this._fileChangeTimer);
    this._fileChangeTimer = setTimeout(() => {
      this._fileChangeTimer = null;
      this.saveFile();
    }, 800);
  }

  // Highlighting rewrites the whole document, so coalesce bursts of input
  // (paste, IME, autofill) into one render per frame instead of one per event.
  scheduleRender() {
    if (this._renderFrame != null) return;
    this._renderFrame = requestAnimationFrame(() => {
      this._renderFrame = null;
      this.renderHighlight();
      this.updateLines();
    });
  }

  cancelScheduledRender() {
    if (this._renderFrame == null) return;
    cancelAnimationFrame(this._renderFrame);
    this._renderFrame = null;
  }

  handleSubmit(event) {
    if (event) event.preventDefault();
    clearTimeout(this._fileChangeTimer);
    this._fileChangeTimer = null;
    this.saveFile();
  }

  saveFile({ keepalive = false } = {}) {
    if (!this.hasTextareaTarget) return;
    if (this.textareaTarget.disabled) return;
    if (!this.hasEndpointValue || !this.endpointValue) return;
    if (!this.hasPageIdValue || !this.pageIdValue) return;

    const body = this.textareaTarget.value;
    if (body === this._lastSaved && !keepalive) return;

    if (this._saveRequest) this._saveRequest.abort();
    const request = new AbortController();
    this._saveRequest = request;

    fetch(this.endpointValue, {
      method: "PATCH",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
      body: JSON.stringify({
        [this.paramKeyValue]: { body },
      }),
      signal: request.signal,
      ...(keepalive ? { keepalive: true } : {}),
    })
      .then((response) => {
        if (!response.ok) throw new Error(`Save failed: ${response.status}`);
        return response.json().catch(() => ({}));
      })
      .then(() => {
        this._lastSaved = body;
      })
      .catch((error) => {
        if (error?.name === "AbortError") return;
        console.error("Autosave failed", error);
        this.setStatus("Save failed");
      })
      .finally(() => {
        if (this._saveRequest === request) this._saveRequest = null;
      });
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text;
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content ?? "";
  }

  updateLines() {
    if (!this.hasTextareaTarget) return;
    const textarea = this.textareaTarget;
    const stack = textarea.closest(".workspace-editor__input-stack");
    const wrapper = textarea.closest(".workspace-editor__textarea-wrapper");
    if (!wrapper) return;

    const count = (textarea.value ?? "").split("\n").length;

    const numbers = Array.from({ length: count }, (_, i) => i + 1).join("\\A ");
    wrapper.style.setProperty("--line-numbers", `"${numbers}"`);

    textarea.style.height = "auto";
    textarea.style.height = `${textarea.scrollHeight}px`;

    // The textarea sits inside the stack, which starts after the line-number
    // gutter, so the wrapper's own width would overhang by the gutter's width.
    // Zero the width first so the grid column reflects only the highlight
    // layer, which is how we measure how wide that layer wants to be.
    textarea.style.width = "0";
    const widths = [
      textarea.scrollWidth,
      stack ? stack.clientWidth : wrapper.clientWidth,
    ];
    if (this.hasHighlightTarget) widths.push(Math.ceil(this.highlightTarget.scrollWidth));
    textarea.style.width = `${Math.max(...widths)}px`;
  }

  renderHighlight() {
    if (!this.hasHighlightTarget || !this.hasTextareaTarget) return;
    const escaped = this.textareaTarget.value
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
    this.highlightTarget.innerHTML =
      escaped
        // HTML
        // <h1>Headings</h1>
        .replace(/^(&lt;h([1-6])(?:\s.*?)?&gt;)(.*?)(&lt;\/h\2&gt;)[ \t]*$/gm,
          (_, open, level, text, close) =>
            `<h${level}><span class="md-syntax">${open}</span><span class="md-accent">${text}</span><span class="md-syntax">${close}</span></h${level}>`
        )
        // <a href="link_to_somewhere.com">Hyperlinks</a>
        .replace(/(&lt;a\s(?:(?!&gt;).)*?href=(?:"|&quot;))((?:(?!"|&quot;).)*)((?:"|&quot;)(?:(?!&gt;).)*&gt;)(.*?)(&lt;\/a&gt;)/g,
          (_, openStart, url, openEnd, text, close) =>
            `<span class="md-syntax">${openStart}</span><span class="md-link">${url}</span><span class="md-syntax">${openEnd}</span><span>${text}</span><span class="md-syntax">${close}</span>`
        )
        // Markdown
        // ## Headings
        .replace(
          /^(#{1,6})([^\S\r\n]+)(.*?)[^\S\r\n]*$/gm,
          '<span class="md-syntax">$1$2</span><span class="md-accent">$3</span>'
        )
        // [[Wikilink]] or [[Wikilink|Alias]] / ![[File]] or ![[File|Alias]]
        // One pass: separate replaces re-match the [[ ]] literals in already-inserted spans.
        .replace(
          /(!?)\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/g,
          (_, bang, target, alias) =>
            `<span class="md-syntax">${bang}[[</span><span class="md-link">${target}</span>` +
            (alias
              ? `<span class="md-syntax">|</span><span class="md-accent">${alias}</span>`
              : "") +
            `<span class="md-syntax">]]</span>`
        )
        // [Hyperlink](https://granite-md.bing-bong.uk)
        .replace(/\[([^\]]+)\]\(([^)]+)\)/g,
          '<span class="md-syntax">[<span class="md-accent">$1</span>](<span class="md-link">$2</span>)</span>'
        )
        // - Lists
        .replace(/^-([ \t]+)(.*)$/gm,
          '<span class="md-syntax">-</span>$1<span>$2</span>'
        )
        // > Blockquotes
        .replace(/^(&gt;)([ \t]+)(.*)$/gm,
          '<span class="md-syntax">></span>$2<span>$3</span>'
        )

        // A \n text node right after a block-level </hN> renders as a phantom
        // empty line under white-space: pre, desyncing the caret. (The \n
        // before <hN> is harmless — the previous line already ended.)
        .replace(/<\/h[1-6]>\n/g, (m) => m.slice(0, -1))

      + "\n";
  }
}
