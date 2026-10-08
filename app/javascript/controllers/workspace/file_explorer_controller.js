import { Controller } from "@hotwired/stimulus"

// Tree navigation for the workspace file explorer.
// Handles folder expand/collapse and page selection highlighting.
// Page navigation itself is a Turbo-frame link; this controller only
// manages the visual active state and notifies listeners.
export default class extends Controller {
  static targets = ["folder", "folderChildren", "folderOpenIcon", "folderClosedIcon", "page", "newPageForm", "newPageInput", "newFolderForm", "newFolderInput", "contextMenu"]

  // Expand or collapse the folder containing the clicked toggle button.
  toggleFolder(event) {
    const button = event.currentTarget
    const item = button.closest('[data-workspace--file-explorer-target="folder"]')
    if (!item) return

    const children = item.querySelector(":scope > [data-workspace--file-explorer-target='folderChildren']")
    if (!children) return

    const expanded = button.getAttribute("aria-expanded") === "true"
    const next = !expanded

    button.setAttribute("aria-expanded", String(next))
    item.setAttribute("aria-expanded", String(next))
    children.hidden = !next

    const openIcon = button.querySelector("[data-workspace--file-explorer-target='folderOpenIcon']")
    const closedIcon = button.querySelector("[data-workspace--file-explorer-target='folderClosedIcon']")
    if (openIcon) openIcon.hidden = !next
    if (closedIcon) closedIcon.hidden = next
  }

  // Reveal the inline "new file" placeholder and focus its input.
  // Buttons carry data-folder-id; the blank-workspace button has none
  // and reveals the root placeholder instead. Enter submits the form;
  // Escape cancels.
  showNewFileForm(event) {
    this.#revealNewFileForm(event.currentTarget.dataset.folderId)
  }

  // "New file" button inside the right-click context menu: uses the
  // folder id stored when the menu was opened, then closes the menu.
  newFileFromContextMenu() {
    const folderId = this.hasContextMenuTarget
      ? this.contextMenuTarget.dataset.folderId
      : null
    this.#revealNewFileForm(folderId)
    this.hideContextMenu()
  }

  // Escape cancels the placeholder; Enter submits natively.
  newPageKeydown(event) {
    if (event.key !== "Escape") return
    event.preventDefault()
    this.#hideNewPageForm(event.currentTarget.closest("li"))
  }

  // Submitting an empty name cancels instead of posting a blank file.
  guardNewPageSubmit(event) {
    const input = event.target.querySelector("input")
    if (input && input.value.trim() === "") {
      event.preventDefault()
      this.#hideNewPageForm(event.target.closest("li"))
    }
  }

  // "New folder" button inside the right-click context menu: uses the
  // folder id stored when the menu was opened, then closes the menu.
  newFolderFromContextMenu() {
    const folderId = this.hasContextMenuTarget
      ? this.contextMenuTarget.dataset.folderId
      : null
    this.#revealNewFolderForm(folderId)
    this.hideContextMenu()
  }

  // Escape cancels the placeholder; Enter submits natively.
  newFolderKeydown(event) {
    if (event.key !== "Escape") return
    event.preventDefault()
    this.#hideNewFolderForm(event.currentTarget.closest("li"))
  }

  // Submitting an empty name cancels instead of posting a blank folder.
  guardNewFolderSubmit(event) {
    const input = event.target.querySelector("input")
    if (input && input.value.trim() === "") {
      event.preventDefault()
      this.#hideNewFolderForm(event.target.closest("li"))
    }
  }

  // Swap a page row for its inline rename form. Enter submits (PATCH),
  // Escape cancels.
  showRenameForm(event) {
    const item = event.currentTarget.closest(".workspace-explorer__page-item")
    if (!item) return

    const link = item.querySelector(".workspace-explorer__page")
    const actions = item.querySelector(".workspace-explorer__page-actions")
    const form = item.querySelector(".workspace-explorer__page-rename")
    if (!form) return

    if (link) link.hidden = true
    if (actions) actions.hidden = true
    form.hidden = false

    const input = form.querySelector("input")
    if (input) {
      input.focus()
      input.select()
    }
  }

  // Escape cancels renaming and restores the row.
  renameKeydown(event) {
    if (event.key !== "Escape") return
    event.preventDefault()
    this.#hideRenameForm(event.target.closest(".workspace-explorer__page-item"))
  }

  // Submitting a blank or unchanged name cancels instead of patching.
  guardRenameSubmit(event) {
    const item = event.target.closest(".workspace-explorer__page-item")
    const input = event.target.querySelector("input")
    if (!input || input.value.trim() === "") {
      event.preventDefault()
      this.#hideRenameForm(item)
    }
  }

  // Highlight the selected page and broadcast it for the editor.
  // Does not preventDefault: the link still drives the
  // `workspace-editor` turbo-frame navigation.
  selectPage(event) {
    const selected = event.currentTarget

    this.pageTargets.forEach((page) => {
      const active = page === selected
      page.classList.toggle("is-active", active)
      if (active) {
        page.setAttribute("aria-current", "page")
      } else {
        page.removeAttribute("aria-current")
      }
    })

    this.dispatch("page-select", {
      detail: { id: selected.dataset.pageId },
      bubbles: true,
      cancelable: false
    })
  }

  // Open an (empty) context menu over a folder row on right-click,
  // positioned at the cursor like in VS Code. The native menu is
  // suppressed; the popup dismisses on click, Escape, resize, or the
  // next contextmenu event.
  showContextMenu(event) {
    event.preventDefault();
    event.stopPropagation();
    if (!this.hasContextMenuTarget) return;

    const menu = this.contextMenuTarget;
    menu.dataset.folderId = event.currentTarget.dataset.folderId ?? "";
    menu.hidden = false;

    const rect = menu.getBoundingClientRect();
    let x = event.clientX;
    let y = event.clientY;
    if (x + rect.width > window.innerWidth - 8) {
      x = Math.max(8, window.innerWidth - rect.width - 8);
    }
    if (y + rect.height > window.innerHeight - 8) {
      y = Math.max(8, window.innerHeight - rect.height - 8);
    }
    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
  }

  // Dismiss the context menu popup.
  hideContextMenu() {
    if (this.hasContextMenuTarget) this.contextMenuTarget.hidden = true;
  }

  // Collapse every folder in the tree.
  collapseAll() {
    this.folderTargets.forEach((item) => this.#setFolderExpanded(item, false))
  }

  // Expand every folder in the tree.
  expandAll() {
    this.folderTargets.forEach((item) => this.#setFolderExpanded(item, true))
  }

  #setFolderExpanded(item, expanded) {
    const button = item.querySelector(".workspace-explorer__folder")
    const children = item.querySelector(":scope > [data-workspace--file-explorer-target='folderChildren']")
    if (!button || !children) return

    button.setAttribute("aria-expanded", String(expanded))
    item.setAttribute("aria-expanded", String(expanded))
    children.hidden = !expanded

    const openIcon = button.querySelector("[data-workspace--file-explorer-target='folderOpenIcon']")
    const closedIcon = button.querySelector("[data-workspace--file-explorer-target='folderClosedIcon']")
    if (openIcon) openIcon.hidden = !expanded
    if (closedIcon) closedIcon.hidden = expanded
  }

  #revealNewFileForm(folderId) {
    const form = folderId
      ? this.newPageFormTargets.find((el) => el.dataset.folderId === folderId)
      : this.newPageFormTargets.find((el) => !el.dataset.folderId)
    if (!form) return

    const folder = form.closest('[data-workspace--file-explorer-target="folder"]')
    if (folder) this.#setFolderExpanded(folder, true)

    // Hide any other open placeholder so only one is visible at a time.
    this.newPageFormTargets.forEach((el) => {
      if (el !== form) {
        el.hidden = true
        const other = el.querySelector("input")
        if (other) other.value = ""
      }
    })

    form.hidden = false
    const input = form.querySelector("input")
    if (input) {
      input.focus()
      input.select()
    }
  }

  #hideNewPageForm(item) {
    if (!item) return
    item.hidden = true
    const input = item.querySelector("input")
    if (input) input.value = ""
  }

  #revealNewFolderForm(folderId) {
    const form = folderId
      ? this.newFolderFormTargets.find((el) => el.dataset.folderId === folderId)
      : this.newFolderFormTargets.find((el) => !el.dataset.folderId)
    if (!form) return

    const folder = form.closest('[data-workspace--file-explorer-target="folder"]')
    if (folder) this.#setFolderExpanded(folder, true)

    // Hide any other open placeholder so only one is visible at a time.
    this.newFolderFormTargets.forEach((el) => {
      if (el !== form) {
        el.hidden = true
        const other = el.querySelector("input")
        if (other) other.value = ""
      }
    })

    form.hidden = false
    const input = form.querySelector("input")
    if (input) {
      input.focus()
      input.select()
    }
  }

  #hideNewFolderForm(item) {
    if (!item) return
    item.hidden = true
    const input = item.querySelector("input")
    if (input) input.value = ""
  }

  #hideRenameForm(item) {
    if (!item) return
    const link = item.querySelector(".workspace-explorer__page")
    const actions = item.querySelector(".workspace-explorer__page-actions")
    const form = item.querySelector(".workspace-explorer__page-rename")
    if (form) {
      form.hidden = true
      const input = form.querySelector("input")
      if (input && link) {
        const name = link.querySelector(".workspace-explorer__page-name")
        input.value = name ? name.textContent : input.defaultValue
      }
    }
    if (link) link.hidden = false
    if (actions) actions.hidden = false
  }
}
