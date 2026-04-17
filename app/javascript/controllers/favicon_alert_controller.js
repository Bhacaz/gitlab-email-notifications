import { Controller } from "@hotwired/stimulus"

// Swaps the favicon to the "notification on" bell when this controller connects.
// Place data-controller="favicon-alert" on an element that is injected by a
// Turbo Stream broadcast so that connect() fires on the stream update.
export default class extends Controller {
  connect() {
    const favicon = document.getElementById("favicon")
    if (favicon) favicon.href = "/favicon-bell-on.svg"
  }

  disconnect() {
    const favicon = document.getElementById("favicon")
    if (favicon) favicon.href = "/favicon-bell.svg"
  }
}
