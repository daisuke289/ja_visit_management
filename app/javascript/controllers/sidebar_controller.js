import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "overlay"]

  connect() {
    // サイドバーの初期状態を設定
    this.sidebar = document.getElementById("sidebar")
    this.overlay = document.getElementById("sidebar-overlay")
  }

  toggle() {
    if (this.sidebar.classList.contains("-translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.sidebar.classList.remove("-translate-x-full")
    this.sidebar.classList.add("translate-x-0")
    this.overlay.classList.remove("hidden")
    document.body.classList.add("overflow-hidden", "md:overflow-auto")
  }

  close() {
    this.sidebar.classList.add("-translate-x-full")
    this.sidebar.classList.remove("translate-x-0")
    this.overlay.classList.add("hidden")
    document.body.classList.remove("overflow-hidden", "md:overflow-auto")
  }
}
