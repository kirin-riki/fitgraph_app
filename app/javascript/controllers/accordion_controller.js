// app/javascript/controllers/accordion_controller.js
import { Controller } from "@hotwired/stimulus"

// アコーディオン開閉（画像ロードを考慮した確実版）
export default class extends Controller {
  static targets = ["item", "content", "icon", "images"]

  toggle(event) {
    const parent  = event.currentTarget.closest("[data-accordion-target='item']")
    const content = parent.querySelector("[data-accordion-target='content']")
    const icon    = parent.querySelector("[data-accordion-target='icon']")
    const imagesWrap  = parent.querySelector("[data-accordion-target='images']")
    const imgs = imagesWrap ? Array.from(imagesWrap.querySelectorAll("img")) : []

    // transition を毎回設定
    content.style.transition = "max-height 0.45s ease, opacity 0.45s ease"
    content.style.overflow = "hidden"
    if (imagesWrap) imagesWrap.style.transition = "opacity 0.35s ease"

    const isHidden = content.classList.contains("hidden") || content.style.maxHeight === "0px" || getComputedStyle(content).display === "none"

    if (isHidden) {
      // === 開く ===
      content.classList.remove("hidden")
      content.style.display = "block"
      content.style.opacity = "0"
      content.style.maxHeight = "0px"
      if (imagesWrap) imagesWrap.style.opacity = "0"

      // 次フレームで暫定高さへ
      requestAnimationFrame(() => {
        this._setMaxHeight(content)
        content.style.opacity = "1"
        icon.textContent = "－"

        // 画像ロードで高さが増えるたびに追従
        const recalc = () => this._setMaxHeight(content)
        let pending = imgs.length
        imgs.forEach(img => {
          if (img.complete) {
            // 既に読み込み済みでも一度再計測
            recalc()
            pending--
          } else {
            img.addEventListener("load", recalc, { once: true })
            img.addEventListener("error", recalc, { once: true })
          }
        })

        // 画像のフェードイン（視覚的）
        if (imagesWrap) {
          // 少し遅らせると自然
          setTimeout(() => (imagesWrap.style.opacity = "1"), 80)
        }

        // すべての画像読み込みが完了したら max-height を解除
        const finalize = () => {
          // トランジション終了後に解除（解除時にカクつかないように）
          const onOpened = () => {
            content.style.maxHeight = "none"
            content.removeEventListener("transitionend", onOpened)
          }
          content.addEventListener("transitionend", onOpened)
        }

        if (pending <= 0) {
          // もう全部読み込み済み
          recalc()
          finalize()
        } else {
          // 最後の1枚が読み込まれたタイミングで finalize
          let loaded = 0
          imgs.forEach(img => {
            const done = () => {
              loaded++
              if (loaded >= pending) {
                recalc()
                finalize()
              }
            }
            if (!img.complete) {
              img.addEventListener("load", done, { once: true })
              img.addEventListener("error", done, { once: true })
            }
          })
        }
      })

    } else {
      // === 閉じる ===
      // いったん現在の高さをセットしてから 0 へ
      const currentHeight = content.scrollHeight
      content.style.maxHeight = currentHeight + "px"
      // reflow
      // eslint-disable-next-line no-unused-expressions
      content.offsetHeight
      content.style.maxHeight = "0px"
      content.style.opacity = "0"
      if (imagesWrap) imagesWrap.style.opacity = "0"
      icon.textContent = "＋"

      // アニメーション後に完全に隠す + スタイルリセット
      const onClosed = () => {
        content.classList.add("hidden")
        content.style.display = ""
        content.style.maxHeight = ""
        content.style.opacity = ""
        content.removeEventListener("transitionend", onClosed)
      }
      content.addEventListener("transitionend", onClosed)
    }
  }

  _setMaxHeight(el) {
    // 一旦 auto にして実高さを取る手もあるが、scrollHeight で十分
    const h = el.scrollHeight
    // 小さすぎるとトランジションしないことがあるので下限を設けてもよい
    el.style.maxHeight = Math.max(h, 1) + "px"
  }
}
