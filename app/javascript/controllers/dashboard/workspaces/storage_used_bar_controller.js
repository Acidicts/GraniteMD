import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar"]
  static values = { percentage: Number }

  connect() {
    this.update(this.percentageValue)
  }

  update(percentage) {
    const clamped = Math.min(100, Math.max(0, Number(percentage) || 0))
    this.barTarget.style.width = `${clamped}%`
  }
}
