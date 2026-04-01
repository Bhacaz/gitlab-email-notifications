import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label"]
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      const original = this.labelTarget.textContent
      this.labelTarget.textContent = "Copied!"
      this.labelTarget.closest("button").classList.add("btn-success")
      setTimeout(() => {
        this.labelTarget.textContent = original
        this.labelTarget.closest("button").classList.remove("btn-success")
      }, 2000)
    })
  }
}
