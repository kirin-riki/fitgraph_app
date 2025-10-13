import { Controller } from "@hotwired/stimulus"

// アコーディオン開閉制御
export default class extends Controller {
  static targets = ["item", "content", "icon"]

  toggle(event) {
    // クリックされた要素の親ブロック（step）を取得
    console.log("Accordion toggle fired!")
    const parent = event.currentTarget.closest("[data-accordion-target='item']")
    const content = parent.querySelector("[data-accordion-target='content']")
    const icon = parent.querySelector("[data-accordion-target='icon']")

    // hiddenクラスをトグル
    content.classList.toggle("hidden")

    // アイコンを「＋ / －」で切り替え
    icon.textContent = content.classList.contains("hidden") ? "＋" : "－"
  }
}
