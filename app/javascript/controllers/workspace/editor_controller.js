import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["textarea", "status"];
  static values = {
    endpoint: String,
    pageId: Number,
  };

  connect() {
    this._lastSaved = this.hasTextareaTarget ? this.textareaTarget.value : "";
    this.updateLines();
  }

  disconnect() {
    // Flush a pending debounced save so quick file-switching doesn't lose edits.
    clearTimeout(this._fileChangeTimer);
    this._fileChangeTimer = null;
    if (this.hasTextareaTarget && this.textareaTarget.value !== this._lastSaved) {
      this.saveFile({ keepalive: true });
    }
    if (this._saveRequest) this._saveRequest.abort();
  }

  fileChange() {
    this.updateLines();
    clearTimeout(this._fileChangeTimer);
    this._fileChangeTimer = setTimeout(() => {
      this._fileChangeTimer = null;
      this.saveFile();
    }, 800);
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
        page: { body },
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
    const wrapper = textarea.parentElement;
    if (!wrapper) return;

    const count = (textarea.value ?? "").split("\n").length;

    const numbers = Array.from({ length: count }, (_, i) => i + 1).join("\\A ");
    wrapper.style.setProperty("--line-numbers", `"${numbers}"`);

    textarea.style.height = "auto";
    textarea.style.height = `${textarea.scrollHeight}px`;

    // Let the wrapper handle horizontal scroll
    textarea.style.width = "0";
    textarea.style.width = `${Math.max(textarea.scrollWidth, wrapper.clientWidth)}px`;
  }

  renderPreview() {}
}
