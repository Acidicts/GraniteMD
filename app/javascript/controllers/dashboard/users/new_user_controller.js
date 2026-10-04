import { Controller } from "@hotwired/stimulus"

const EMAIL_FORMAT = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const PASSWORD_RULES = {
  length:  (v) => v.length >= 8,
  upper:   (v) => /[A-Z]/.test(v),
  lower:   (v) => /[a-z]/.test(v),
  number:  (v) => /\d/.test(v),
  special: (v) => /[^A-Za-z0-9\s]/.test(v),
}

export default class extends Controller {
  static targets = [
    "usernameHint", "usernameHintIcon",
    "emailHint", "emailHintIcon",
    "passwordRule",
    "passwordConfirmationHint", "passwordConfirmationHintIcon",
    "password", "passwordConfirmation",
  ]

  connect() {
    this.requests = { username: null, email: null }

    this.renderHintUsername(null, null)
    this.renderHintEmail(null, null)
    this.renderPasswordRules()
    this.renderPasswordMatch()
  }

  disconnect() {
    this.cancel("username")
    this.cancel("email")
  }

  // ---- Unique username / email -------------------------------------------

  checkUniqueUsername(event) {
    this.checkUnique(event, "username", "/unique_username")
  }

  checkUniqueEmail(event) {
    this.checkUnique(event, "email", "/unique_email", (v) => EMAIL_FORMAT.test(v))
  }

  checkUnique(event, field, endpoint, isValid = () => true) {
    const input = event.target
    const value = input.value.trim()

    this.cancel(field)
    this.render(field, input, null)

    if (value === "" || !isValid(value)) return

    const request = new AbortController()
    this.requests[field] = request

    fetch(`${endpoint}?${field}=${encodeURIComponent(value)}`, {
      headers: { Accept: "application/json" },
      signal: request.signal,
    })
      .then((response) => {
        if (!response.ok) throw new Error(`unexpected status ${response.status}`)
        return response.json()
      })
      .then(
        ({ available }) => {
          if (this.isCurrent(field, request, input, value)) this.render(field, input, available)
        },
        (error) => {
          if (error.name === "AbortError") return
          if (this.isCurrent(field, request, input, value)) this.render(field, input, null)
        },
      )
      .finally(() => {
        if (this.requests[field] === request) this.requests[field] = null
      })
  }

  cancel(field) {
    const request = this.requests[field]
    if (!request) return

    request.abort()
    this.requests[field] = null
  }

  isCurrent(field, request, input, value) {
    return this.requests[field] === request && input.value.trim() === value
  }

  render(field, input, available) {
    if (field === "username") this.renderHintUsername(input, available)
    else this.renderHintEmail(input, available)
  }

  renderHintUsername(input, available) {
    if (!this.hasUsernameHintTarget) return
    this.setHint(input, available, this.usernameHintTarget, this.usernameHintIconTarget, {
      pending: "Start Typing",
      available: "Username is available",
      taken: "Username is already taken",
    })
  }

  renderHintEmail(input, available) {
    if (!this.hasEmailHintTarget) return
    this.setHint(input, available, this.emailHintTarget, this.emailHintIconTarget, {
      pending: "",
      available: "Email is available",
      taken: "Email is already in use",
    })
  }

  // ---- Password strength + match -----------------------------------------

  // Called on input in the password field
  checkSecurePassword() {
    this.renderPasswordRules()
    this.renderPasswordMatch() // password changed, so re-check the match
  }

  // Called on input in the confirmation field
  checkMatchingPasswords() {
    this.renderPasswordMatch()
  }

  passwordMeetsRules(value = this.passwordTarget.value) {
    return Object.values(PASSWORD_RULES).every((test) => test(value))
  }

  renderPasswordRules() {
    const value = this.passwordTarget.value
    const untouched = value === ""

    this.passwordRuleTargets.forEach((item) => {
      const test = PASSWORD_RULES[item.dataset.rule]
      const icon = item.querySelector(".hint-icon")
      const met = test ? test(value) : false

      item.classList.toggle("error", !untouched && !met)
      item.classList.toggle("met", !untouched && met)

      if (!icon) return
      icon.classList.remove("hint-icon-error", "hint-icon-success", "hint-icon-neutral")
      if (untouched) {
        icon.textContent = "-"
        item.style.display = "block"
        icon.classList.add("hint-icon-neutral")
      } else if (met) {
        icon.textContent = "✓"
        item.style.display = "none"
        icon.classList.add("hint-icon-success")
      } else {
        icon.textContent = "×"
        item.style.display = "block"
        icon.classList.add("hint-icon-error")
      }
    })

    if (untouched) this.passwordTarget.removeAttribute("aria-invalid")
    else this.passwordTarget.setAttribute("aria-invalid", this.passwordMeetsRules(value) ? "false" : "true")
  }

  renderPasswordMatch() {
    const confirmation = this.passwordConfirmationTarget.value
    const state = confirmation === "" ? null : confirmation === this.passwordTarget.value

    this.setHint(
      this.passwordConfirmationTarget,
      state,
      this.passwordConfirmationHintTarget,
      this.passwordConfirmationHintIconTarget,
      { pending: "", available: "Passwords match", taken: "Passwords do not match" },
    )
  }

  // ---- Shared hint renderer ----------------------------------------------
  // state: null = neutral, true = good, false = bad

  setHint(input, state, hint, icon, messages) {
    if (input) {
      if (state === null) input.removeAttribute("aria-invalid")
      else input.setAttribute("aria-invalid", state ? "false" : "true")
    }

    icon.classList.remove("hint-icon-error", "hint-icon-success", "hint-icon-neutral")

    if (state === null) {
      const hasPending = messages.pending !== ""
      hint.textContent = messages.pending
      icon.textContent = hasPending ? "-" : ""
      icon.style.display = hasPending ? "inline-block" : "none"
      icon.classList.add("hint-icon-neutral")
      hint.classList.remove("error")
    } else if (state) {
      hint.textContent = messages.available
      icon.textContent = "✓"
      icon.style.display = "inline-block"
      icon.classList.add("hint-icon-success")
      hint.classList.remove("error")
    } else {
      hint.textContent = messages.taken
      icon.textContent = "×"
      icon.style.display = "inline-block"
      icon.classList.add("hint-icon-error")
      hint.classList.add("error")
    }
  }
}