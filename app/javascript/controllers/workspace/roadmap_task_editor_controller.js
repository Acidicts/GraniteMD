import { Controller } from "@hotwired/stimulus";

// Autosaving editor for a single roadmap task inside the overlay dialog.
// Mirrors workspace--editor (debounced PATCH of JSON) but handles the three
// overlay fields -- header, body, assignee -- instead of a single page body.
//
// Debounce is 3s from the last keystroke/change, per the overlay spec (the
// page editor uses a shorter delay). A pending edit is flushed on disconnect
// so closing the dialog mid-debounce does not lose it.
export default class extends Controller {
  static targets = ["header", "body", "assignee", "status", "pill", "menu", "search", "list", "empty"];
  static values = {
    endpoint: String,
    taskId: Number,
    delay: { type: Number, default: 3000 },
  };

  connect() {
    this._lastSaved = this.currentState();
  }

  disconnect() {
    clearTimeout(this._saveTimer);
    this._saveTimer = null;
    if (this.isDirty) this.save({ keepalive: true });
    if (this._saveRequest) this._saveRequest.abort();
  }

  // Called on input (header/body) and after an assignee pick. Restarts the
  // 3s countdown on every keystroke/selection.
  schedule() {
    clearTimeout(this._saveTimer);
    this._saveTimer = setTimeout(() => {
      this._saveTimer = null;
      this.save();
    }, this.delayValue);
  }

  // Flush any pending debounced edit immediately, e.g. when the overlay
  // is dismissed by clicking off it. No-op when nothing changed.
  flush() {
    if (!this.isDirty) {
      clearTimeout(this._saveTimer);
      this._saveTimer = null;
      return;
    }
    clearTimeout(this._saveTimer);
    this._saveTimer = null;
    this.save();
  }

  // Assignee menu: a pill button (current assignee or "Unassigned") toggling
  // an inline member list, like the board cards' picker. A pick updates the
  // hidden field + pill optimistically and joins the same 3s autosave path,
  // so the overlay never fights the shared picker dialog or goes stale.
  toggleMenu() {
    if (!this.hasMenuTarget) return;
    if (this.menuTarget.hidden) this.openMenu();
    else this.closeMenu();
  }

  openMenu() {
    if (!this.hasMenuTarget) return;
    if (this.hasSearchTarget) this.searchTarget.value = "";
    this.filter();
    this.menuTarget.hidden = false;
    if (this.hasPillTarget) this.pillTarget.setAttribute("aria-expanded", "true");
    this.searchTarget?.focus();
  }

  closeMenu() {
    if (!this.hasMenuTarget) return;
    this.menuTarget.hidden = true;
    if (this.hasPillTarget) this.pillTarget.setAttribute("aria-expanded", "false");
  }

  // Clicks anywhere outside the pill/menu dismiss the open menu. The pill and
  // menu opt out by containing the click (same pattern as the roadmap
  // editor's dismissForms).
  dismissMenu(event) {
    if (!this.hasMenuTarget || this.menuTarget.hidden) return;
    if (
      event.target?.closest?.(
        '[data-workspace--roadmap-task-editor-target="pill"], [data-workspace--roadmap-task-editor-target="menu"]',
      )
    )
      return;
    this.closeMenu();
  }

  menuKeydown(event) {
    if (event.key === "Escape") {
      this.closeMenu();
      this.pillTarget?.focus();
    }
  }

  choose(event) {
    const option = event.target?.closest?.("[data-assignee-id]");
    if (!option || !this.hasAssigneeTarget) return;

    this.assigneeTarget.value = option.dataset.assigneeId ?? "";
    if (this.hasListTarget) {
      for (const el of this.listTarget.querySelectorAll("[data-assignee-id]")) {
        el.setAttribute("aria-selected", String(el === option));
      }
    }
    this.renderPill(option);
    this.closeMenu();
    this.pillTarget?.focus();
    this.schedule();
  }

  renderPill(option) {
    if (!this.hasPillTarget) return;
    const display = option.dataset.assigneeDisplay ?? "";
    const initial = option.dataset.assigneeInitial ?? display.charAt(0).toUpperCase();

    this.pillTarget.classList.toggle("roadmap-task__assignee--empty", !display);
    this.pillTarget.textContent = "";
    if (!display) {
      this.pillTarget.textContent = "Unassigned";
      return;
    }
    const avatar = document.createElement("span");
    avatar.className = "roadmap-task__assignee-avatar";
    avatar.setAttribute("aria-hidden", "true");
    avatar.textContent = initial;
    const label = document.createElement("span");
    label.className = "roadmap-task__assignee-name";
    label.textContent = display;
    const clear = document.createElement("button");
    clear.type = "button";
    clear.className = "roadmap-task__assignee-clear";
    clear.setAttribute("data-action", "click->workspace--roadmap-task-editor#clear");
    clear.setAttribute("aria-label", "Unassign");
    clear.setAttribute("title", "Unassign");
    clear.textContent = "×";
    this.pillTarget.append(avatar, label, clear);
  }

  // The pill is a div with role="button" (a native <button> cannot contain
  // the clear <button>), so keyboard activation needs an explicit handler.
  pillKeydown(event) {
    if (event.target !== this.pillTarget) return;
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.toggleMenu();
    }
  }

  // The "x" inside the pill clears the assignee and joins the same 3s
  // autosave path as a menu pick. Stops propagation so the bubbled click
  // does not also hit the pill's toggleMenu.
  clear(event) {
    event?.preventDefault?.();
    event?.stopPropagation?.();
    if (!this.hasAssigneeTarget) return;

    this.assigneeTarget.value = "";
    if (this.hasListTarget) {
      for (const el of this.listTarget.querySelectorAll("[data-assignee-id]")) {
        el.setAttribute("aria-selected", String((el.dataset.assigneeId ?? "") === ""));
      }
    }
    this.renderPill({ dataset: { assigneeDisplay: "", assigneeInitial: "" } });
    this.closeMenu();
    this.pillTarget?.focus();
    this.schedule();
  }

  filter() {
    if (!this.hasListTarget) return;

    const query = this.searchTarget?.value.trim().toLowerCase() ?? "";
    let matches = 0;

    for (const option of this.listTarget.querySelectorAll("[data-assignee-name]")) {
      const visible = option.dataset.assigneeName.includes(query);
      option.hidden = !visible;
      if (visible) matches += 1;
    }

    if (this.hasEmptyTarget) this.emptyTarget.hidden = matches > 0;
  }

  handleSubmit(event) {
    if (event) event.preventDefault();
    clearTimeout(this._saveTimer);
    this._saveTimer = null;
    this.save();
  }

  save({ keepalive = false } = {}) {
    if (!this.hasEndpointValue || !this.endpointValue) return;
    if (!this.hasTaskIdValue || !this.taskIdValue) return;

    const state = this.currentState();
    if (!this.dirty(state) && !keepalive) return;

    if (this._saveRequest) this._saveRequest.abort();
    const request = new AbortController();
    this._saveRequest = request;

    this.setStatus("Saving…");

    fetch(this.endpointValue, {
      method: "PATCH",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
      body: JSON.stringify({ roadmap_task: state }),
      signal: request.signal,
      ...(keepalive ? { keepalive: true } : {}),
    })
      .then((response) => {
        if (!response.ok) throw new Error(`Save failed: ${response.status}`);
        return response.text();
      })
      .then((html) => {
        this._lastSaved = state;
        this.setStatus("Saved");
        this.reloadTaskCard(html);
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

  currentState() {
    return {
      header: this.hasHeaderTarget ? this.headerTarget.value : "",
      body: this.hasBodyTarget ? this.bodyTarget.value : "",
      assignee_id: this.hasAssigneeTarget ? this.assigneeTarget.value : "",
    };
  }

  dirty(state = this.currentState()) {
    const last = this._lastSaved ?? {};
    return (
      state.header !== last.header ||
      state.body !== last.body ||
      String(state.assignee_id ?? "") !== String(last.assignee_id ?? "")
    );
  }

  get isDirty() {
    return this.dirty();
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text;
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content ?? "";
  }

  // Reload the affected card via Turbo so the column reflects the saved
  // header/body/assignee (including unassign) without a full page visit.
  // The update endpoint answers turbo-stream with a replace for
  // roadmap-task-<id>; rendering it swaps the card in place.
  reloadTaskCard(html) {
    if (html?.includes?.("<turbo-stream") && window.Turbo?.renderStreamMessage) {
      window.Turbo.renderStreamMessage(html);
      return;
    }
    const id = this.taskIdValue;
    const frame = id ? document.getElementById(`roadmap-task-${id}`) : null;
    if (frame?.reload) {
      try {
        frame.reload();
      } catch {
        /* no src to reload from -- card stays until next visit */
      }
    }
  }
}
