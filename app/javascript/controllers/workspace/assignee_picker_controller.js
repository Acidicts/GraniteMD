import { Controller } from "@hotwired/stimulus";

// One dialog per roadmap page, shared by every unassigned card. It lives on the
// editor wrapper rather than on the cards because Turbo replaces a card's frame
// on every move and every save, and a per-card dialog would be torn down each
// time. Triggers are therefore matched by delegation rather than by binding an
// action on each pill.
export default class extends Controller {
  static targets = ["dialog", "form", "search", "list", "empty"];

  // Only reachable once a trigger has supplied a URL, so the form can never be
  // posted at the collection endpoint (which would create a task).
  open(event) {
    const trigger = event.target.closest("[data-roadmap-assignee-trigger]");
    if (!trigger) return;
    if (!this.hasDialogTarget || !this.hasFormTarget) return;

    event.preventDefault();

    this.formTarget.action = trigger.dataset.assignUrl;
    if (this.hasSearchTarget) this.searchTarget.value = "";
    this.filter();

    this.dialogTarget.showModal();
    // After showModal, so the caret does not land on a display:none input.
    this.searchTarget?.focus();
  }

  close() {
    if (!this.hasDialogTarget) return;
    if (this.dialogTarget.open) this.dialogTarget.close();
  }

  // The panel fills the dialog's box, so a click that reaches the dialog itself
  // is by definition on the backdrop the browser draws behind it.
  backdrop(event) {
    if (event.target !== this.dialogTarget) return;
    this.close();
  }

  filter() {
    if (!this.hasListTarget) return;

    const query = this.searchTarget?.value.trim().toLowerCase() ?? "";
    let matches = 0;

    for (const option of this.listTarget.querySelectorAll("[data-assignee-name]")) {
      const visible = option.dataset.assigneeName.includes(query);
      // The options set their own display, which would otherwise beat the
      // browser's built-in [hidden] handling.
      option.hidden = !visible;
      if (visible) matches += 1;
    }

    if (this.hasEmptyTarget) this.emptyTarget.hidden = matches > 0;
  }

  // The card is re-rendered by the response's turbo_stream, so the dialog only
  // has to get out of the way.
  submit() {
    this.close();
  }
}
