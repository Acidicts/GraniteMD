import { Controller } from "@hotwired/stimulus"

const COLLAPSED_CLASS = "nav-collapsed"
const STORAGE_KEY = "granitemd-nav-collapsed"

export default class extends Controller {
  static targets = ["nav", "toggle", "icon"]

  connect() {
    try {
      this.collapsed = window.localStorage.getItem(STORAGE_KEY) === "1"
    } catch {
      this.collapsed = false
    }
    this.apply()
  }

  toggle() {
    this.collapsed = !this.collapsed
    try {
      window.localStorage.setItem(STORAGE_KEY, this.collapsed ? "1" : "0")
    } catch {
      // ignore storage errors (private mode, etc.)
    }
    this.apply()
    this.element.dispatchEvent(
      new CustomEvent("layouts:nav-toggle", { bubbles: true, detail: { collapsed: this.collapsed } })
    )
  }

  apply() {
    this.element.classList.toggle(COLLAPSED_CLASS, this.collapsed)
    this.navTarget.classList.toggle("is-collapsed", this.collapsed)
    this.navTarget.setAttribute("aria-hidden", String(this.collapsed))
    if (this.collapsed) {
      this.navTarget.setAttribute("inert", "")
    } else {
      this.navTarget.removeAttribute("inert")
    }

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", String(!this.collapsed))
      this.toggleTarget.setAttribute("aria-label", this.collapsed ? "Show navigation" : "Hide navigation")
      this.toggleTarget.setAttribute("title", this.collapsed ? "Show navigation" : "Hide navigation")
    }
  }
}
