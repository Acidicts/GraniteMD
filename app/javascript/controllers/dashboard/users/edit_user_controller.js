import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];
  static values = { endpoint: String };

  connect() {
    this.handleFieldChange = () => this.update();
    this.fields = Array.from(this.element.querySelectorAll(".field"));
    this.fields.forEach((field) => {
      field.addEventListener("change", this.handleFieldChange);
    });
  }

  disconnect() {
    this.fields?.forEach((field) => {
      field.removeEventListener("change", this.handleFieldChange);
    });
    this.fields = [];
    this.pendingRequest?.abort();
    this.pendingRequest = null;
  }

  update() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit();
      return;
    }

    const form = this.element.querySelector("form");
    if (form) {
      form.requestSubmit();
      return;
    }

    if (!this.hasEndpointValue || !this.endpointValue) return;

    const data = new FormData();
    this.fields.forEach((field) => {
      if (field.name) data.append(field.name, field.value);
    });

    this.pendingRequest?.abort();
    const request = new AbortController();
    this.pendingRequest = request;

    fetch(this.endpointValue, {
      method: "PATCH",
      headers: {
        Accept: "text/vnd.turbo-stream.html, text/html",
        "X-CSRF-Token": this.csrfToken,
        "X-Requested-With": "XMLHttpRequest",
      },
      body: data,
      signal: request.signal,
    })
      .then((response) => {
        if (!response.ok) throw new Error(`Update failed: ${response.status}`);
        return response.text();
      })
      .then((html) => {
        if (window.Turbo?.renderStreamMessage && html.includes("<turbo-stream")) {
          window.Turbo.renderStreamMessage(html);
        } else if (window.Turbo?.visit) {
          window.Turbo.visit(window.location.toString());
        }
      })
      .catch((error) => {
        if (error?.name === "AbortError") return;
        console.error("Profile update failed", error);
      })
      .finally(() => {
        if (this.pendingRequest === request) this.pendingRequest = null;
      });
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content ?? "";
  }
}
