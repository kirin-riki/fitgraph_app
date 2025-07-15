import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]

  connect() {
    this.hide()
    // Turboイベントのリスナーを追加
    document.addEventListener("turbo:visit", this.show.bind(this))
    document.addEventListener("turbo:load", this.hide.bind(this))
    document.addEventListener("turbo:before-cache", this.hide.bind(this))
  }

  disconnect() {
    // イベントリスナーのクリーンアップ
    document.removeEventListener("turbo:visit", this.show.bind(this))
    document.removeEventListener("turbo:load", this.hide.bind(this))
    document.removeEventListener("turbo:before-cache", this.hide.bind(this))
  }

  show() {
    console.log("ローディング表示: hiddenを外します");
    this.spinnerTarget.classList.remove("hidden")
  }

  hide() {
    console.log("ローディング非表示: hiddenを付与します");
    this.spinnerTarget.classList.add("hidden")
  }
} 