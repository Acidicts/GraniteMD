import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]

  show() {
    const tooltip = this.tooltipTarget
    const trigger = this.element

    tooltip.style.display = "block"

    const tipHeight = tooltip.offsetHeight
    const gap = 8

    if (trigger.offsetTop < tipHeight + gap) {
      tooltip.style.top = `calc(100% + ${gap}px)`
      tooltip.classList.add("brand-info-icon__tooltip--below")
    } else {
      tooltip.style.top = `calc(-${tipHeight}px - ${gap}px)`
      tooltip.classList.remove("brand-info-icon__tooltip--below")
    }
  }

  hide() {
    this.tooltipTarget.style.display = "none"
    this.tooltipTarget.classList.remove("brand-info-icon__tooltip--below")
  }
}