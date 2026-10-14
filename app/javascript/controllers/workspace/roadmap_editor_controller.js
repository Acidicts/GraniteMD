import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["catagoryForm", "taskForm"];
  // .../roadmaps/:id/items -- the move endpoint is this plus the task id.
  static values = { itemsUrl: String };

  connect() {
    this.dragged = null;
    this.dropTarget = null;

    this.onDragStart = (event) => this.dragStart(event);
    this.onDragOver = (event) => this.dragOver(event);
    this.onDrop = (event) => this.drop(event);
    this.onDragEnd = () => this.dragEnd();

    this.element.addEventListener("dragstart", this.onDragStart);
    this.element.addEventListener("dragover", this.onDragOver);
    this.element.addEventListener("drop", this.onDrop);
    this.element.addEventListener("dragend", this.onDragEnd);
  }

  disconnect() {
    this.element.removeEventListener("dragstart", this.onDragStart);
    this.element.removeEventListener("dragover", this.onDragOver);
    this.element.removeEventListener("drop", this.onDrop);
    this.element.removeEventListener("dragend", this.onDragEnd);
    // Turbo swaps this frame out mid-drag often enough to matter; a move that
    // lands after the frame is gone would fail against a stale catagory.
    this.moveRequest?.abort();
    this.moveRequest = null;
  }

  dragStart(event) {
    // Interactive elements inside a card (the assignee pill, the pencil) are
    // clickable, not drag handles -- starting a drag from them would swallow
    // the click in some browsers.
    if (event.target.closest("button, a, input, textarea, dialog")) return;
    const card = event.target.closest(".roadmap-task");
    if (!card) return;

    this.dragged = card;
    card.classList.add("roadmap-task--dragging");
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", card.dataset.roadmapTaskId ?? "");
  }

  dragOver(event) {
    if (!this.dragged) return;
    const catagory = event.target.closest(".category");
    if (!catagory) return;

    event.preventDefault();
    event.dataTransfer.dropEffect = "move";
    this.highlightDropTarget(catagory);
  }

  drop(event) {
    if (!this.dragged) return;
    const catagory = event.target.closest(".category");
    if (!catagory) return;

    event.preventDefault();
    // Already in this column: appending would silently reorder it.
    if (catagory !== this.dragged.parentElement) {
      const card = this.dragged;
      const previous = card.parentElement;
      catagory.appendChild(card);
      this.persistMove(card, catagory, previous);
    }
    this.dragEnd();
  }

  // Persists the move the drop just made. The card is already in its new
  // column, so a failure puts it back where it came from.
  persistMove(card, catagory, previous) {
    const taskId = card.dataset.roadmapTaskId;
    if (!taskId || !this.hasItemsUrlValue) return;

    // Send the column's position, matching Roadmap#get_category. The server
    // turns it back into the row to store.
    const columns = [...catagory.parentElement.querySelectorAll(".category")];
    const index = columns.indexOf(catagory);
    if (index < 0) return;

    this.moveRequest?.abort();
    this.moveRequest = new AbortController();

    fetch(`${this.itemsUrlValue}/${taskId}`, {
      method: "PATCH",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
      body: JSON.stringify({ roadmap_task: { category_index: index } }),
      signal: this.moveRequest.signal,
    })
      .then((response) => {
        if (!response.ok) throw new Error(`Move failed: ${response.status}`);
      })
      .catch((error) => {
        if (error?.name === "AbortError") return;
        console.error("Moving item failed", error);
        previous?.appendChild(card);
      })
      .finally(() => {
        this.moveRequest = null;
      });
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content ?? "";
  }

  // Fires on Escape and on drop alike, so it is the one place the drag state
  // is cleared. Deliberately does no persisting: dragend also fires when the
  // drag is cancelled, and dropTarget is null then.
  dragEnd() {
    this.dragged?.classList.remove("roadmap-task--dragging");
    this.dragged = null;
    this.highlightDropTarget(null);
  }

  highlightDropTarget(catagory) {
    if (this.dropTarget === catagory) return;
    this.dropTarget?.classList.remove("roadmap-task--drop-target");
    this.dropTarget = catagory;
    catagory?.classList.add("roadmap-task--drop-target");
  }

  newCatagoryForm() {
    if (!this.hasCatagoryFormTarget) return;
    this.catagoryFormTarget.classList.toggle("hidden");
    if (this.hasTaskFormTarget) this.taskFormTarget.classList.add("hidden");
  }

  newRoadmapItemForm(event) {
    if (!this.hasTaskFormTarget) return;

    const button = event.target.closest("[data-roadmap-catagory-id]");
    const field = this.taskFormTarget.querySelector(
      "input[name='roadmap_task[category]']",
    );
    if (button && field) field.value = button.dataset.roadmapCatagoryId;

    if (this.hasCatagoryFormTarget)
      this.catagoryFormTarget.classList.add("hidden");
    this.taskFormTarget.classList.remove("hidden");
  }

  newRoadmapItem(event) {
    this.hideForms();

    const header = event.target.querySelector(
      "input[name='roadmap_task[header]']",
    );
    if (header && header.value.trim() === "") {
      event.preventDefault();
    }
  }

  newCatagory(event) {
    this.hideForms();

    const input = event.target.querySelector("input");
    if (input && input.value.trim() === "") {
      event.preventDefault();
    }
  }

  dismissForms(event) {
    if (event.target.closest("[data-roadmap-editor-toggle]")) return;

    this.hideUnlessClickedInside(this.catagoryFormTarget, event.target);
    this.hideUnlessClickedInside(this.taskFormTarget, event.target);
  }

  hideUnlessClickedInside(form, clicked) {
    if (!form || form.contains(clicked)) return;
    form.classList.add("hidden");
  }

  hideForms() {
    if (this.hasCatagoryFormTarget)
      this.catagoryFormTarget.classList.add("hidden");
    if (this.hasTaskFormTarget) this.taskFormTarget.classList.add("hidden");
  }
}
