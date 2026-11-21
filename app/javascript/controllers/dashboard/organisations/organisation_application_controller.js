import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"]
  
  connect() {
    this.formTarget.style.display = "none"
  }

  toggle() {
    if (this.formTarget.style.display == "none") {
        this.formTarget.style.display = "block"
    } else {
        this.formTarget.style.display = "none"
    }
  }
}
