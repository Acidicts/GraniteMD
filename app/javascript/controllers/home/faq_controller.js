import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["question", "template"]
  static values = { questions: Array }

  connect() {
    this.render()
  }

  render() {
    if (!this.hasTemplateTarget) return

    this.questionsValue.forEach(([title, answer]) => {
      const clone = this.templateTarget.content.cloneNode(true)
      clone.querySelector(".question-title").textContent = title
      clone.querySelector(".question-answer").textContent = answer
      this.element.appendChild(clone)
    })
  }

  toggle(event) {
    const clicked = event.currentTarget.closest(".question")
    if (!clicked) return
    const wasOpen = clicked.classList.contains("open")

    this.questionTargets.forEach((question) => {
      question.classList.remove("open")
      question.querySelector(".question-header")?.setAttribute("aria-expanded", "false")
    })

    if (!wasOpen) {
      clicked.classList.add("open")
      clicked.querySelector(".question-header")?.setAttribute("aria-expanded", "true")
    }
  }
}
