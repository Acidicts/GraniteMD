import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  update(event) {
    const id = event.target.value
    fetch(`/dashboard/workspaces/new_users?id=${encodeURIComponent(id)}`, {
      headers: { Accept: "text/html" },
    })
      .then((response) => {
        if (!response.ok) throw new Error(`unexpected status ${response.status}`)
        return response.text()
      })
      .then((html) => {
        const frame = document.getElementById("new_workspace_organisation_users")
        if (frame) frame.outerHTML = html
      })
  }
}
