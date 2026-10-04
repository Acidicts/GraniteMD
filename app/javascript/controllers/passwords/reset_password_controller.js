import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["password", "passwordConfirmation", "submitButton"];

  connect() {
    this.match();
  }

  match() {
    const password = this.passwordTarget.value;
    const confirmation = this.passwordConfirmationTarget.value;
    const passwordsMatch = password.length > 0 && password === confirmation;

    this.submitButtonTarget.disabled = !passwordsMatch;
  }
}