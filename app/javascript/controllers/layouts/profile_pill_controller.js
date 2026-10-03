import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "links" ]

  connect() {
  }

  clicked() {
    this.linksTarget.classList.toggle("hidden");
  }

  close(event) {
    if (this.element.contains(event.target)) return
    this.linksTarget.classList.add("hidden");
  }
}
