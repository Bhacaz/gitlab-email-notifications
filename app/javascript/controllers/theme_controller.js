import { Controller } from "@hotwired/stimulus"

const LIGHT_THEME = "pastel"
const DARK_THEME = "dim"

export default class extends Controller {
  static targets = ["icon"]

  connect() {
    this.#updateIcon()
  }

  toggle() {
    const current = document.documentElement.getAttribute("data-theme")
    const next = current === DARK_THEME ? LIGHT_THEME : DARK_THEME
    document.documentElement.setAttribute("data-theme", next)
    localStorage.setItem("theme", next)
    this.#updateIcon()
  }

  #updateIcon() {
    if (!this.hasIconTarget) return
    const isDark = document.documentElement.getAttribute("data-theme") === DARK_THEME
    this.iconTarget.className = isDark ? "bi bi-sun" : "bi bi-moon-stars"
  }
}
