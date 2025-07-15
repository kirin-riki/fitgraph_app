import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "graphView", "photoView", "tabGraph", "tabPhoto", "weightChart",
    "statsTable", "statsContent", "periodTab", "photoPeriodTab",
    "layerTab", "compareTab", "layerView", "compareView"
  ]

  connect() {
    this.currentPeriod = "3m"
    this.setMainTab("graph")
    this.initTabs()
    this.initPeriodTabs()
    this.renderChart("3m")
    this.updateStatsTable("3m")
    this.setPhotoSubTab("layer")
  }

  // タブ切り替え
  initTabs() {
    if (this.hasTabGraphTarget && this.hasTabPhotoTarget) {
      this.tabGraphTarget.addEventListener("click", () => {
        this.setMainTab("graph")
      })
      this.tabPhotoTarget.addEventListener("click", () => {
        this.setMainTab("photo")
      })
    }
    if (this.hasLayerTabTarget && this.hasCompareTabTarget) {
      this.layerTabTarget.addEventListener("click", () => this.setPhotoSubTab("layer"))
      this.compareTabTarget.addEventListener("click", () => this.setPhotoSubTab("compare"))
    }
  }

  setMainTab(active) {
    if (!this.hasGraphViewTarget || !this.hasPhotoViewTarget) return
    if (active === "graph") {
      this.graphViewTarget.classList.remove("hidden")
      this.photoViewTarget.classList.add("hidden")
      this.tabGraphTarget.classList.add("bg-violet-500", "text-white")
      this.tabGraphTarget.classList.remove("bg-violet-100", "text-violet-500")
      this.tabPhotoTarget.classList.remove("bg-violet-500", "text-white")
      this.tabPhotoTarget.classList.add("bg-violet-100", "text-violet-500")
      if (this.hasStatsTableTarget) this.statsTableTarget.classList.remove("hidden")
      if (this.hasStatsContentTarget) this.statsContentTarget.classList.remove("hidden")
      this.renderChart("3m")
    } else {
      this.graphViewTarget.classList.add("hidden")
      this.photoViewTarget.classList.remove("hidden")
      this.tabPhotoTarget.classList.add("bg-violet-500", "text-white")
      this.tabPhotoTarget.classList.remove("bg-violet-100", "text-violet-500")
      this.tabGraphTarget.classList.remove("bg-violet-500", "text-white")
      this.tabGraphTarget.classList.add("bg-violet-100", "text-violet-500")
      if (this.hasStatsTableTarget) this.statsTableTarget.classList.add("hidden")
    }
  }

  // 期間タブ初期化
  initPeriodTabs() {
    if (this.hasPeriodTabTarget) {
      this.periodTabTargets.forEach(btn => {
        btn.addEventListener("click", () => {
          this.periodTabTargets.forEach(b => {
            b.classList.remove("bg-violet-500", "text-white")
            b.classList.add("bg-violet-100", "text-violet-600")
          })
          btn.classList.remove("bg-violet-100", "text-violet-600")
          btn.classList.add("bg-violet-500", "text-white")
          this.renderChart(btn.dataset.period)
          this.updateStatsTable(btn.dataset.period)
        })
      })
    }
    if (this.hasPhotoPeriodTabTarget) {
      this.photoPeriodTabTargets.forEach(btn => {
        btn.addEventListener("click", () => {
          this.photoPeriodTabTargets.forEach(b => {
            b.classList.remove("bg-violet-500", "text-white")
            b.classList.add("bg-violet-100", "text-violet-600")
          })
          btn.classList.remove("bg-violet-100", "text-violet-600")
          btn.classList.add("bg-violet-500", "text-white")
          // photo-switcherコントローラのsetPeriodを呼び出す
          const photoSwitcherEl = document.querySelector('[data-controller="photo-switcher"]');
          if (photoSwitcherEl && photoSwitcherEl.StimulusController) {
            photoSwitcherEl.StimulusController.setPeriod(btn.dataset.period)
          } else if (window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier) {
            const ctrl = window.Stimulus.getControllerForElementAndIdentifier(photoSwitcherEl, "photo-switcher");
            if (ctrl && typeof ctrl.setPeriod === "function") {
              ctrl.setPeriod(btn.dataset.period)
            }
          }
          // 比較ビューも期間に合わせて更新
          this.updateCompareView(btn.dataset.period)
        })
      })
    }
  }

  // グラフ描画（Chart.js）
  renderChart(period = "3m") {
    if (!this.hasWeightChartTarget) return
    // ... Chart.js描画ロジックをここに移植 ...
  }

  // 統計表更新
  updateStatsTable(period) {
    // ... 統計表更新ロジックをここに移植 ...
  }

  // 写真タブ切り替え
  setPhotoSubTab(tab) {
    if (!this.hasLayerTabTarget || !this.hasCompareTabTarget || !this.hasLayerViewTarget || !this.hasCompareViewTarget) return
    if (tab === "layer") {
      this.layerTabTarget.classList.add("bg-violet-500", "text-white")
      this.layerTabTarget.classList.remove("bg-violet-100", "text-violet-500")
      this.compareTabTarget.classList.remove("bg-violet-500", "text-white")
      this.compareTabTarget.classList.add("bg-violet-100", "text-violet-500")
      this.layerViewTarget.classList.remove("hidden")
      this.compareViewTarget.classList.add("hidden")
    } else {
      this.layerTabTarget.classList.remove("bg-violet-500", "text-white")
      this.layerTabTarget.classList.add("bg-violet-100", "text-violet-500")
      this.compareTabTarget.classList.add("bg-violet-500", "text-white")
      this.compareTabTarget.classList.remove("bg-violet-100", "text-violet-500")
      this.layerViewTarget.classList.add("hidden")
      this.compareViewTarget.classList.remove("hidden")
      this.updateCompareView()
    }
  }

  updateCompareView(period = "3m") {
    // 比較ビューの画像切り替えロジック
    const photoSwitcherEl = document.querySelector('[data-controller="photo-switcher"]');
    if (!photoSwitcherEl) return;
    const allPhotos = JSON.parse(photoSwitcherEl.dataset.photos);
    const placeholder = photoSwitcherEl.dataset.placeholder || '/assets/avatar_placeholder.png';
    const now = new Date();
    let start = new Date(now);
    switch (period) {
      case "1w": start = new Date(now.getTime() - 7 * 86400000); break;
      case "3w": start = new Date(now.getTime() - 21 * 86400000); break;
      case "1m": start.setMonth(now.getMonth() - 1); break;
      case "3m": default: start.setMonth(now.getMonth() - 3); break;
    }
    const startStr = start.toISOString().slice(0, 10);
    const nowStr = now.toISOString().slice(0, 10);
    // 昇順ソート
    const sortedPhotos = allPhotos.slice().sort((a, b) => a.date.localeCompare(b.date));
    const filtered = sortedPhotos.filter(p => p.date >= startStr && p.date <= nowStr);
    const beforeImg = document.getElementById("compare-before");
    const afterImg = document.getElementById("compare-after");
    if (filtered.length === 0) {
      if (beforeImg) beforeImg.src = placeholder;
      if (afterImg) afterImg.src = placeholder;
    } else {
      const before = filtered[0];
      const after = filtered[filtered.length - 1];
      if (beforeImg) beforeImg.src = before.url || placeholder;
      if (afterImg) afterImg.src = after.url || placeholder;
    }
  }
} 