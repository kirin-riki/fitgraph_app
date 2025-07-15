import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "slider"]

  connect() {
    this.allPhotos = JSON.parse(this.element.dataset.photos)
    this.period = "3m"
    this.periodButtons = document.querySelectorAll("#photo-view .period-tab")
    this.setPeriod(this.period)
    this.periodButtons.forEach(btn => {
      btn.addEventListener("click", (e) => {
        e.preventDefault()
        this.setPeriod(btn.dataset.period)
      })
    })
  }

  setPeriod(period) {
    this.period = period
    // ボタンの色付け
    this.periodButtons.forEach(btn => {
      if (btn.dataset.period === period) {
        btn.classList.add("bg-purple-500", "text-white")
        btn.classList.remove("bg-purple-100", "text-purple-600")
      } else {
        btn.classList.remove("bg-purple-500", "text-white")
        btn.classList.add("bg-purple-100", "text-purple-600")
      }
    })
    // 期間ごとの日付範囲を計算
    const now = new Date()
    let start = new Date(now)
    switch (period) {
      case "1w":
        start = new Date(now.getTime() - 7 * 86400000)
        break
      case "3w":
        start = new Date(now.getTime() - 21 * 86400000)
        break
      case "1m":
        start.setMonth(now.getMonth() - 1)
        break
      case "3m":
      default:
        start.setMonth(now.getMonth() - 3)
        break
    }
    // フィルタリング
    const startStr = start.toISOString().slice(0, 10)
    const nowStr = now.toISOString().slice(0, 10)
    this.photos = this.allPhotos.filter(p => p.date >= startStr && p.date <= nowStr)
    // 画像・スライダー更新
    this.updateImage(0)
    if (this.hasSliderTarget) {
      this.sliderTarget.max = this.photos.length
      this.sliderTarget.value = 1
      this.sliderTarget.style.display = this.photos.length > 1 ? '' : 'none'
    }
  }

  slide() {
    const index = parseInt(this.sliderTarget.value, 10) - 1
    this.updateImage(index)
  }

  updateImage(index) {
    if (!this.hasImageTarget) return;

    if (this.photos.length === 0) {
      // プレースホルダー画像を使用
      const placeholder = this.element.dataset.placeholder || '/assets/avatar_placeholder.png'
      this.imageTarget.src = placeholder
    } else {
      const photo = this.photos[index]
      if (photo && photo.url) {
        this.imageTarget.src = photo.url
      } else {
        // フォールバックとしてプレースホルダー画像を使用
        const placeholder = this.element.dataset.placeholder || '/assets/avatar_placeholder.png'
        this.imageTarget.src = placeholder
      }
    }
  }
} 