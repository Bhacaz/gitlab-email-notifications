import { Controller } from "@hotwired/stimulus"
import { post, destroy } from "@rails/request.js"

// Manages Web Push subscription state.
// Usage: data-controller="push-subscription"
//        data-push-subscription-vapid-public-key-value="<base64url key>"
export default class extends Controller {
  static values = {
    vapidPublicKey: String,
    subscribed: Boolean
  }

  static targets = ["icon", "label"]

  async connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.element.hidden = true
      return
    }

    const registration = await navigator.serviceWorker.ready
    const sub = await registration.pushManager.getSubscription()
    this.subscribedValue = !!sub
    this.#updateUI()
  }

  async toggle() {
    if (this.subscribedValue) {
      await this.#unsubscribe()
    } else {
      await this.#subscribe()
    }
  }

  async #subscribe() {
    try {
      const permission = await Notification.requestPermission()
      if (permission !== "granted") return

      const registration = await navigator.serviceWorker.ready
      const sub = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.#urlBase64ToUint8Array(this.vapidPublicKeyValue)
      })

      const json = sub.toJSON()
      await post("/push_subscription", {
        body: JSON.stringify({
          push_subscription: {
            endpoint: json.endpoint,
            keys: { p256dh: json.keys.p256dh, auth: json.keys.auth }
          }
        }),
        contentType: "application/json"
      })

      this.subscribedValue = true
      this.#updateUI()
    } catch (err) {
      console.error("Push subscribe error:", err)
      if (err.name === "AbortError") {
        this.#showError("Push notifications are blocked by your browser or its privacy settings (e.g. Brave Shields). Please allow Google push services or try another browser.")
      } else if (err.name === "NotAllowedError") {
        this.#showError("Notification permission was denied.")
      } else {
        this.#showError("Could not enable push notifications: " + err.message)
      }
    }
  }

  async #unsubscribe() {
    try {
      const registration = await navigator.serviceWorker.ready
      const sub = await registration.pushManager.getSubscription()
      if (sub) {
        const endpoint = sub.endpoint
        await sub.unsubscribe()
        await destroy("/push_subscription", {
          body: JSON.stringify({ endpoint }),
          contentType: "application/json"
        })
      }
      this.subscribedValue = false
      this.#updateUI()
    } catch (err) {
      console.error("Push unsubscribe error:", err)
    }
  }

  #updateUI() {
    if (this.hasIconTarget) {
      this.iconTarget.className = this.subscribedValue
        ? "bi bi-bell-fill text-primary"
        : "bi bi-bell-slash"
    }
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = this.subscribedValue
        ? "Disable push notifications"
        : "Enable push notifications"
    }
  }

  #showError(message) {
    // Dispatch a custom event so the app can display a flash message
    this.dispatch("error", { detail: { message } })
    // Also show a simple alert as fallback
    alert(message)
  }

  // Converts a URL-safe base64 string to a Uint8Array for the VAPID key
  #urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = atob(base64)
    return Uint8Array.from([...rawData].map((c) => c.charCodeAt(0)))
  }
}
