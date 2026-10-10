import { Controller } from "@hotwired/stimulus"

// Dropzone for a single image file input.
// Handles drag & drop, clipboard paste, and click-to-browse with a live preview.
//
// Usage:
// <div class="dropzone" data-controller="components--image-dropzone"
//      data-action="dragover->components--image-dropzone#dragover dragleave->components--image-dropzone#dragleave drop->components--image-dropzone#drop paste->components--image-dropzone#paste click->components--image-dropzone#browse keydown->components--image-dropzone#keydown"
//      tabindex="0" role="button" aria-label="Upload image">
//   <input type="file" data-components--image-dropzone-target="input"
//          data-action="change->components--image-dropzone#preview" accept="image/*" class="dropzone__input">
//   <img hidden data-components--image-dropzone-target="preview" class="dropzone__preview" alt="Image preview">
//   <p class="dropzone__prompt" data-components--image-dropzone-target="prompt">Drag &amp; drop, paste, or click to upload</p>
// </div>
export default class extends Controller {
  static targets = ["input", "preview", "prompt"]

  connect() {
    if (this.hasPromptTarget) this.defaultPrompt = this.promptTarget.textContent
    if (this.inputTarget.files.length > 0) this.showFile(this.inputTarget.files[0])
  }

  disconnect() {
    this.revokePreviewUrl()
  }

  dragover(event) {
    event.preventDefault()
    this.element.classList.add("is-dragover")
    if (event.dataTransfer) event.dataTransfer.dropEffect = "copy"
  }

  dragleave(event) {
    // Only remove the highlight when leaving the dropzone itself, not a child.
    if (!this.element.contains(event.relatedTarget)) this.element.classList.remove("is-dragover")
  }

  drop(event) {
    event.preventDefault()
    this.element.classList.remove("is-dragover")
    const file = [...(event.dataTransfer?.files ?? [])].find((f) => f.type.startsWith("image/"))
    if (file) this.setFile(file)
  }

  paste(event) {
    const file = [...(event.clipboardData?.files ?? [])].find((f) => f.type.startsWith("image/"))
    if (!file) return
    event.preventDefault()
    this.setFile(file)
  }

  browse() {
    this.inputTarget.click()
  }

  keydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.browse()
    }
  }

  // Change event from the file input (native dialog selection).
  preview() {
    const file = this.inputTarget.files[0]
    if (file) this.showFile(file)
  }

  setFile(file) {
    const transfer = new DataTransfer()
    transfer.items.add(file)
    this.inputTarget.files = transfer.files
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.showFile(file)
  }

  showFile(file) {
    this.revokePreviewUrl()
    if (this.hasPreviewTarget) {
      this.previewUrl = URL.createObjectURL(file)
      this.previewTarget.src = this.previewUrl
      this.previewTarget.hidden = false
    }
    if (this.hasPromptTarget) this.promptTarget.textContent = file.name
  }

  revokePreviewUrl() {
    if (this.previewUrl) {
      URL.revokeObjectURL(this.previewUrl)
      this.previewUrl = null
    }
  }
}
