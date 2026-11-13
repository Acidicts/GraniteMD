import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button", "rotating"]
  static values = { autoopen: { type: Boolean, default: false } }

  connect() {
    this.outsideClick = this.outsideClick.bind(this)
    this.escape = this.escape.bind(this)

    if (this.autoopenValue) {
      this.open()
    } else {
      this.close()
    }
  }

  toggle(event) {
    event.preventDefault()
    this.element.classList.contains("is-open") ? this.close() : this.open()
  }

  open() {
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.element.classList.add("is-open")
    document.addEventListener("click", this.outsideClick)
    document.addEventListener("keydown", this.escape)
  }

  close() {
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.element.classList.remove("is-open")
    document.removeEventListener("click", this.outsideClick)
    document.removeEventListener("keydown", this.escape)
  }

  outsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  escape(event) {
    if (event.key === "Escape") this.close()
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
    document.removeEventListener("keydown", this.escape)
  }
}