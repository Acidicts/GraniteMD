import { Controller } from "@hotwired/stimulus"

// Tree navigation for the workspace file explorer.
// Handles folder expand/collapse and page selection highlighting.
// Page navigation itself is a Turbo-frame link; this controller only
// manages the visual active state and notifies listeners.
export default class extends Controller {
  static targets = ["folder", "folderChildren", "folderOpenIcon", "folderClosedIcon", "page", "newPageForm", "newPageInput", "newFolderForm", "newFolderInput", "newRoadmapForm", "newRoadmapInput", "newWorkspaceFileForm", "newWorkspaceFileInput", "contextMenu", "folderMenu", "pageMenu", "folderRenameButton", "pageDeleteButton"]

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

  // Reveal the inline "new folder" placeholder and focus its input.
  // Mirrors showNewFileForm for the empty-state "New folder" button.
  showNewFolderForm(event) {
    this.#revealNewFolderForm(event.currentTarget.dataset.folderId)
  }

  // "New file" button inside the right-click context menu: uses the
  // folder id stored when the menu was opened, then closes the menu.
  newFileFromContextMenu() {
    const folderId = this.hasContextMenuTarget ? this.contextMenuTarget.dataset.id : null
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
    const folderId = this.hasContextMenuTarget ? this.contextMenuTarget.dataset.id : null
    this.#revealNewFolderForm(folderId)
    this.hideContextMenu()
  }

  // "New roadmap" button inside the right-click context menu: uses the
  // folder id stored when the menu was opened, then closes the menu.
  newRoadmapFromContextMenu() {
    const folderId = this.hasContextMenuTarget ? this.contextMenuTarget.dataset.id : null
    this.#revealNewRoadmapForm(folderId)
    this.hideContextMenu()
  }

  // "Upload file" button in the header/empty state: reveals the inline
  // upload form for the button's folder id. Mirrors showNewFileForm.
  showWorkspaceFileForm(event) {
    this.#revealWorkspaceFileForm(event.currentTarget.dataset.folderId)
  }

  // "Upload file" button inside the right-click context menu: uses the
  // folder id stored when the menu was opened, then closes the menu.
  uploadWorkspaceFileFromContextMenu() {
    const folderId = this.hasContextMenuTarget ? this.contextMenuTarget.dataset.id : null
    this.#revealWorkspaceFileForm(folderId)
    this.hideContextMenu()
  }

  // Escape cancels the upload placeholder.
  workspaceFileKeydown(event) {
    if (event.key !== "Escape") return
    event.preventDefault()
    this.#hideWorkspaceFileForm(event.target.closest("li"))
  }

  // Auto-submit the upload form as soon as a file is chosen — via the
  // native dialog, drag & drop, or paste. The dropzone dispatches a
  // bubbling change event for all three, so one handler covers them.
  submitWorkspaceFileForm(event) {
    const input = event.target.closest('input[type="file"]') ?? event.target
    if (!input.files || input.files.length === 0) return
    const form = input.closest("form")
    if (form) form.requestSubmit()
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

  // Escape cancels the placeholder; Enter submits natively.
  newRoadmapKeydown(event) {
    if (event.key !== "Escape") return
    event.preventDefault()
    this.#hideNewRoadmapForm(event.currentTarget.closest("li"))
  }

  // Submitting an empty name cancels instead of posting a blank roadmap.
  guardNewRoadmapSubmit(event) {
    const input = event.target.querySelector("input")
    if (input && input.value.trim() === "") {
      event.preventDefault()
      this.#hideNewRoadmapForm(event.target.closest("li"))
    }
  }

  // Submitting without a chosen file cancels instead of posting.
  guardNewWorkspaceFileSubmit(event) {
    const input = event.target.querySelector('input[type="file"]')
    if (!input || !input.files || input.files.length === 0) {
      event.preventDefault()
      this.#hideWorkspaceFileForm(event.target.closest("li"))
    }
  }

  // "Rename" in the page context menu: reveal the inline rename form for
  // the page the menu was opened on, then close the menu.
  renamePageFromContextMenu() {
    const menu = this.hasContextMenuTarget ? this.contextMenuTarget : null
    const kind = menu?.dataset.kind
    const id = (kind === "page" || kind === "roadmap") ? menu.dataset.id : null
    this.hideContextMenu()
    if (!id) return
    this.#showPageRename(this.#pageItemFor(id, kind))
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

  // Swap a folder row for its inline rename form. Enter submits (PATCH),
  // Escape cancels.
  showFolderRenameForm(event) {
    const item = event.currentTarget.closest('[data-workspace--file-explorer-target="folder"]')
    this.#showFolderRename(item)
  }

  // "Rename folder" button inside the context menu: uses the folder id
  // stored when the menu was opened, then closes the menu. The root
  // folder has no row, so there is nothing to rename for it.
  renameFolderFromContextMenu() {
    const folderId = this.hasContextMenuTarget ? this.contextMenuTarget.dataset.id : null
    this.hideContextMenu()
    if (!folderId) return
    this.#showFolderRename(this.#folderItemFor(folderId))
  }

  // Escape cancels folder renaming and restores the row.
  folderRenameKeydown(event) {
    if (event.key !== "Escape") return
    event.preventDefault()
    this.#hideFolderRename(event.target.closest('[data-workspace--file-explorer-target="folder"]'))
  }

  // Submitting a blank name cancels instead of patching.
  guardFolderRenameSubmit(event) {
    const item = event.target.closest('[data-workspace--file-explorer-target="folder"]')
    const input = event.target.querySelector("input")
    if (!input || input.value.trim() === "") {
      event.preventDefault()
      this.#hideFolderRename(item)
    }
  }

  // Highlight the selected page and broadcast it for the editor.
  // Does not preventDefault: the link still drives the
  // `workspace-editor` turbo-frame navigation.
  selectPage(event) {
    const selected = event.currentTarget

    this.#markActive(selected)

    this.dispatch("page-select", {
      detail: { id: selected.dataset.pageId },
      bubbles: true,
      cancelable: false
    })
  }

  connect() {
    this._openPage = (event) => this.activatePage(event.detail?.id, event.detail?.kind)
    document.addEventListener("workspace:open-page", this._openPage)
  }

  disconnect() {
    document.removeEventListener("workspace:open-page", this._openPage)
  }

  // Highlight the page or file the quick switcher opened. The switcher
  // navigates the editor frame without going through the explorer's own
  // links, so the tree would otherwise keep marking the old row as
  // active.
  activatePage(id, kind) {
    if (!id) return
    const item = this.#switcherItemFor(String(id), kind)
    if (!item) return

    const link = item.querySelector(".workspace-explorer__page")
    if (link) this.#markActive(link)
    item.scrollIntoView({ block: "nearest" })

    // Fold every ancestor folder open so the opened row is actually
    // visible; its rows stay in the DOM behind the `hidden` flag.
    let folder = item.closest('[data-workspace--file-explorer-target="folder"]')
    while (folder) {
      this.#setFolderExpanded(folder, true)
      folder = folder.parentElement?.closest('[data-workspace--file-explorer-target="folder"]')
    }
  }

  // Open the menu from a ⋯ button, anchored below the button like in VS
  // Code. Reuses the same popup as right-click and adapts its entries to
  // the row it was opened on (folder or page). Toggles closed when
  // clicking the same row's button again. stopPropagation keeps the
  // click@window->hideContextMenu handler from closing it at once.
  showMenu(event) {
    event.preventDefault();
    event.stopPropagation();
    if (!this.hasContextMenuTarget) return;

    const menu = this.contextMenuTarget;
    const { kind, id } = this.#menuContextFor(event.currentTarget);
    if (!menu.hidden && menu.dataset.kind === kind && menu.dataset.id === id) {
      this.hideContextMenu();
      return;
    }

    this.#populateContextMenu(kind, id);
    menu.hidden = false;

    const buttonRect = event.currentTarget.getBoundingClientRect();
    const menuRect = menu.getBoundingClientRect();
    let x = buttonRect.right - menuRect.width;
    let y = buttonRect.bottom + 4;
    x = Math.min(Math.max(8, x), Math.max(8, window.innerWidth - menuRect.width - 8));
    y = Math.min(Math.max(8, y), Math.max(8, window.innerHeight - menuRect.height - 8));
    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
  }

  // Open the context menu over a folder or page row on right-click,
  // positioned at the cursor like in VS Code. The native menu is
  // suppressed; the popup dismisses on click, Escape, resize, or the
  // next contextmenu event.
  showContextMenu(event) {
    event.preventDefault();
    event.stopPropagation();
    if (!this.hasContextMenuTarget) return;

    const menu = this.contextMenuTarget;
    const { kind, id } = this.#menuContextFor(event.currentTarget);
    this.#populateContextMenu(kind, id);
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
    this.contextMenuTargets.forEach((menu) => { menu.hidden = true });
  }

  // Collapse every folder in the tree.
  collapseAll() {
    this.folderTargets.forEach((item) => this.#setFolderExpanded(item, false))
  }

  // Expand every folder in the tree.
  expandAll() {
    this.folderTargets.forEach((item) => this.#setFolderExpanded(item, true))
  }

  // Mark one page row as the active one and clear the others.
  #markActive(selected) {
    this.pageTargets.forEach((page) => {
      const active = page === selected
      page.classList.toggle("is-active", active)
      if (active) {
        page.setAttribute("aria-current", "page")
      } else {
        page.removeAttribute("aria-current")
      }
    })
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

  #revealNewRoadmapForm(folderId) {
    const form = folderId
      ? this.newRoadmapFormTargets.find((el) => el.dataset.folderId === folderId)
      : this.newRoadmapFormTargets.find((el) => !el.dataset.folderId)
    if (!form) return

    const folder = form.closest('[data-workspace--file-explorer-target="folder"]')
    if (folder) this.#setFolderExpanded(folder, true)

    // Hide any other open placeholder so only one is visible at a time.
    this.newRoadmapFormTargets.forEach((el) => {
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

  #hideNewRoadmapForm(item) {
    if (!item) return
    item.hidden = true
    const input = item.querySelector("input")
    if (input) input.value = ""
  }

  #hideWorkspaceFileForm(item) {
    if (!item) return
    item.hidden = true
    const input = item.querySelector('input[type="file"]')
    if (input) input.value = ""
  }

  #revealWorkspaceFileForm(folderId) {
    const form = folderId
      ? this.newWorkspaceFileFormTargets.find((el) => el.dataset.folderId === folderId)
      : this.newWorkspaceFileFormTargets.find((el) => !el.dataset.folderId)
    if (!form) return

    const folder = form.closest('[data-workspace--file-explorer-target="folder"]')
    if (folder) this.#setFolderExpanded(folder, true)

    // Hide any other open upload placeholder so only one is visible at a time.
    this.newWorkspaceFileFormTargets.forEach((el) => {
      if (el !== form) {
        el.hidden = true
        const other = el.querySelector('input[type="file"]')
        if (other) other.value = ""
      }
    })

    form.hidden = false
    const input = form.querySelector('input[type="file"]')
    if (input) input.focus()
  }

  #hideRenameForm(item) {
    if (!item) return
    const link = item.querySelector(".workspace-explorer__page")
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
  }

  // Work out whether the menu was opened for a folder, a page or a
  // roadmap, and which one. Folder rows carry data-folder-id; page rows
  // data-page-id; roadmap rows data-roadmap-id.
  #menuContextFor(element) {
    if (element.dataset.pageId) {
      return { kind: "page", id: element.dataset.pageId }
    }
    if (element.dataset.roadmapId) {
      return { kind: "roadmap", id: element.dataset.roadmapId }
    }
    return { kind: "folder", id: element.dataset.folderId ?? "" }
  }

  // Show the entries that belong to the row the menu was opened on and,
  // for pages and roadmaps, point the Delete entry at that row's delete URL.
  #populateContextMenu(kind, id) {
    const menu = this.contextMenuTarget
    menu.dataset.kind = kind
    menu.dataset.id = id

    if (this.hasFolderMenuTarget) this.folderMenuTarget.hidden = kind !== "folder"
    if (this.hasPageMenuTarget) this.pageMenuTarget.hidden = kind !== "page" && kind !== "roadmap"

    if (kind === "folder") {
      this.#toggleFolderRenameButton(id)
    } else if (this.hasPageDeleteButtonTarget) {
      const item = this.#pageItemFor(id, kind)
      const name = item?.querySelector(".workspace-explorer__page-name")?.textContent?.trim() || "this file"
      const ext = item?.dataset.extension ?? "md"
      const label = ext ? `${name}.${ext}` : name
      this.pageDeleteButtonTarget.setAttribute("href", item?.dataset.deleteUrl || "#")
      this.pageDeleteButtonTarget.setAttribute("data-turbo-confirm", `Delete ${label}? This can't be undone.`)
    }
  }

  #pageItemFor(id, kind = "page") {
    if (!id) return null
    const selector = kind === "roadmap"
      ? `.workspace-explorer__roadmap-item[data-roadmap-id="${id}"]`
      : `.workspace-explorer__page-item[data-page-id="${id}"]`
    return this.element.querySelector(selector)
  }

  // The row of the page or file the quick switcher opened. Page ids and
  // file ids come from different tables and can be the same number, so
  // the row is found by its own id ("workspace-page-12" /
  // "workspace-file-12") instead of the shared data-page-id attribute.
  #switcherItemFor(id, kind) {
    if (!id) return null
    const selector = kind === "file" ? `#workspace-file-${id}` : `#workspace-page-${id}`
    return this.element.querySelector(selector)
  }

  #showPageRename(item) {
    if (!item) return
    const link = item.querySelector(".workspace-explorer__page")
    const form = item.querySelector(".workspace-explorer__page-rename")
    if (!form) return

    if (link) link.hidden = true
    form.hidden = false

    const input = form.querySelector("input")
    if (input) {
      input.focus()
      input.select()
    }
  }

  #folderItemFor(folderId) {
    if (!folderId) return null
    return this.element.querySelector(
      `[data-workspace--file-explorer-target="folder"][data-folder-id="${folderId}"]`
    )
  }

  // The root folder has no row in the tree, so the Rename entry only
  // applies when the menu was opened for a rendered folder.
  #toggleFolderRenameButton(folderId) {
    if (!this.hasFolderRenameButtonTarget) return
    this.folderRenameButtonTarget.hidden = !this.#folderItemFor(folderId)
  }

  #showFolderRename(item) {
    if (!item) return
    const button = item.querySelector(":scope > .workspace-explorer__folder-row > .workspace-explorer__folder")
    const menuButton = item.querySelector(":scope > .workspace-explorer__folder-row > .workspace-explorer__menu-btn")
    const form = item.querySelector(":scope > .workspace-explorer__folder-row > .workspace-explorer__folder-rename")
    if (!form) return

    if (button) button.hidden = true
    if (menuButton) menuButton.hidden = true
    form.hidden = false

    const input = form.querySelector("input")
    if (input) {
      input.focus()
      input.select()
    }
  }

  #hideFolderRename(item) {
    if (!item) return
    const button = item.querySelector(":scope > .workspace-explorer__folder-row > .workspace-explorer__folder")
    const menuButton = item.querySelector(":scope > .workspace-explorer__folder-row > .workspace-explorer__menu-btn")
    const form = item.querySelector(":scope > .workspace-explorer__folder-row > .workspace-explorer__folder-rename")
    if (form) {
      form.hidden = true
      const input = form.querySelector("input")
      if (input) {
        const name = item.querySelector(":scope > .workspace-explorer__folder-row .workspace-explorer__folder-name")
        input.value = name ? name.textContent : input.defaultValue
      }
    }
    if (button) button.hidden = false
    if (menuButton) menuButton.hidden = false
  }
}
