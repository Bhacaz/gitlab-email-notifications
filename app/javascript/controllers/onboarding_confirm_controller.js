import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static values = { url: String }

  async confirm() {
    await patch(this.urlValue, { responseKind: "json" })
    window.location = "/"
  }
}
