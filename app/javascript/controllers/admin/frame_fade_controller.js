import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.onClick = this.onClick.bind(this)
    this.onBeforeFrameRender = this.onBeforeFrameRender.bind(this)
    this.onFrameRender = this.onFrameRender.bind(this)

    this.isFadingOut = false

    document.addEventListener("turbo:click", this.onClick)
    document.addEventListener("turbo:before-frame-render", this.onBeforeFrameRender)
    document.addEventListener("turbo:frame-render", this.onFrameRender)
  }

  disconnect() {
    document.removeEventListener("turbo:click", this.onClick)
    document.removeEventListener("turbo:before-frame-render", this.onBeforeFrameRender)
    document.removeEventListener("turbo:frame-render", this.onFrameRender)
  }

  onClick(event) {
    const trigger = event.target.closest(
      "a[data-turbo-frame='admin_frame_content'], button[data-turbo-frame='admin_frame_content'], form[data-turbo-frame='admin_frame_content']"
    )
    if (!trigger) return

    this.isFadingOut = true
    this.element.classList.add("is-fading")
  }

  onBeforeFrameRender(event) {
    if (event.target !== this.element) return

    if (this.isFadingOut) {
      event.preventDefault()
      this.isFadingOut = false

      const resume = () => {
        event.detail.resume()
      }

      const onEnd = (e) => {
        if (e.propertyName === "opacity") {
          this.element.removeEventListener("transitionend", onEnd)
          clearTimeout(timeout)
          resume()
        }
      }

      this.element.addEventListener("transitionend", onEnd)
      const timeout = setTimeout(() => {
        this.element.removeEventListener("transitionend", onEnd)
        resume()
      }, 350)
      return
    }

    // Ensure new content starts hidden, then fade in after render.
    this.element.classList.add("is-fading")
  }

  onFrameRender(event) {
    if (event.target !== this.element) return

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.element.classList.remove("is-fading")
      })
    })
  }
}
