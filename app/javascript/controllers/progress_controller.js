import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static targets = [
    "graphView", "photoView", "tabGraph", "tabPhoto", "weightChart",
    "statsTable", "statsContent", "periodTab",
    "photoSubTabs", "layerTab", "compareTab", "layerView", "compareView"
  ]

  static values = {
    labels: Array,
    weights: Array,
    fatRates: Array,
    targetWeight: Number,
    allRecords: Array
  }

  connect() {
    this.currentPeriod = "3m"
    this.currentMainTab = "graph"
    this.chart = null

    this.initTabs()
    this.initPeriodTabs()
    this.renderChart("3m")
    this.updateStatsTable("3m")

    // ✅ layerTab/compareTab が存在する場合のみ初期化
    if (this.hasLayerTabTarget && this.hasCompareTabTarget) {
      this.setPhotoSubTab("layer")
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  /* ---------- グラフ描画 ---------- */
  renderChart(period = "3m") {
    if (!this.hasWeightChartTarget) return

    const ctx = this.weightChartTarget.getContext("2d")
    const chart = Chart.getChart(ctx)
    if (chart) chart.destroy()

    const rows = this.buildChartData(period)
    const labels = rows.map(r => {
      const t = new Date(r.label)
      return `${t.getMonth() + 1}/${t.getDate()}`
    })
    const weights = rows.map(r => r.weight)
    const fats = rows.map(r => r.fat)

    const vw = weights.filter(v => v !== null)
    const vf = fats.filter(v => v !== null)

    const fMin = vf.length ? Math.floor(Math.min(...vf)) - 5 : undefined
    const fMax = vf.length ? Math.ceil(Math.max(...vf)) + 5 : undefined
    let wMin = vw.length ? Math.floor(Math.min(...vw)) - 5 : undefined
    let wMax = vw.length ? Math.ceil(Math.max(...vw)) + 5 : undefined

    const target = this.targetWeightValue
    if (target && vw.length > 0) {
      const min = Math.min(...vw)
      const max = Math.max(...vw)
      if (target < min) wMin = Math.floor(target) - 5
      if (target > max) wMax = Math.ceil(target) + 5
    }

    const isMobile = window.innerWidth < 768

    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels,
        datasets: [
          {
            label: "体重(kg)",
            data: weights,
            borderColor: "rgba(255,99,132,0.9)",
            backgroundColor: "rgba(255,99,132,0.2)",
            yAxisID: "y1",
                spanGaps: true,
            borderWidth: isMobile ? 2 : 3,
            pointRadius: isMobile ? 3 : 4
          },
          {
            label: "体脂肪率(%)",
            data: fats,
            borderColor: "rgba(75,192,192,0.7)",
            backgroundColor: "rgba(75,192,192,0.2)",
            yAxisID: "y2",
                spanGaps: true,
            borderWidth: isMobile ? 2 : 3,
            pointRadius: isMobile ? 3 : 4
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            title: { display: true, text: "日付" },
            ticks: { maxTicksLimit: isMobile ? 7 : 10 }
          },
          y1: {
            type: "linear",
            position: "left",
            min: wMin,
            max: wMax,
            title: { display: true, text: "体重(kg)" }
          },
          y2: {
            type: "linear",
            position: "right",
            min: fMin,
            max: fMax,
            title: { display: true, text: "体脂肪率(%)" },
            grid: { drawOnChartArea: false }
          }
        },
        plugins: {
          legend: { position: "top" },
          tooltip: {
            callbacks: {
              afterBody: () =>
                target ? `目標体重: ${target}kg` : ""
            }
          }
        }
      },
      plugins: [{
        id: "targetWeightMarker",
        afterDraw: (chart) => {
          if (!target) return
          const y = chart.scales["y1"].getPixelForValue(target)
          const ctx = chart.ctx
          const radius = isMobile ? 10 : 12
          ctx.save()
          ctx.beginPath()
          ctx.arc(chart.chartArea.left - radius - 6, y, radius, 0, 2 * Math.PI)
          ctx.fillStyle = "rgba(139, 92, 246, 0.8)"
          ctx.fill()
          ctx.font = `bold ${isMobile ? 10 : 12}px sans-serif`
          ctx.fillStyle = "#fff"
          ctx.textAlign = "center"
          ctx.textBaseline = "middle"
          ctx.fillText(String(target), chart.chartArea.left - radius - 6, y)
          ctx.setLineDash([5, 5])
          ctx.strokeStyle = "rgba(139, 92, 246, 0.8)"
          ctx.lineWidth = 2
          ctx.beginPath()
          ctx.moveTo(chart.chartArea.left, y)
          ctx.lineTo(chart.chartArea.right, y)
          ctx.stroke()
          ctx.restore()
        }
      }]
    })
  }

  /* ---------- データ整形 ---------- */
  buildChartData(period) {
    const now = new Date()
    let start = new Date(now)
    switch (period) {
      case "1w": start = new Date(now - 7 * 86400000); break
      case "3w": start = new Date(now - 21 * 86400000); break
      case "1m": start.setMonth(now.getMonth() - 1); break
      default: start.setMonth(now.getMonth() - 3)
    }

    const range = []
    const cur = new Date(start)
    while (cur <= now) {
      range.push(cur.toISOString().slice(0, 10))
      cur.setDate(cur.getDate() + 1)
    }

    const map = {}
    this.labelsValue.forEach((d, i) => {
      const wRaw = parseFloat(this.weightsValue[i])
      const fRaw = parseFloat(this.fatRatesValue[i])
      const w = Number.isFinite(wRaw) ? wRaw : undefined
      const f = Number.isFinite(fRaw) ? fRaw : undefined
      map[d] = { w, f }
    })

    return range.map(d => ({
      label: d,
      weight: map[d]?.w ?? null,
      fat: map[d]?.f ?? null
    }))
  }

  /* ---------- 統計テーブル更新 ---------- */
  updateStatsTable(period) {
    const now = new Date()
    let start = new Date(now)
    switch (period) {
      case "1w": start = new Date(now - 7 * 86400000); break
      case "3w": start = new Date(now - 21 * 86400000); break
      case "1m": start.setMonth(now.getMonth() - 1); break
      default: start.setMonth(now.getMonth() - 3)
    }

    const records = this.allRecordsValue.filter(r => {
      const d = new Date(r[0])
      return d >= start && d <= now
    })

    if (!records.length) return

    const first = records[0]
    const last = records[records.length - 1]
    const firstWeight = +first[1]
    const lastWeight = +last[1]
    const firstFat = +first[2]
    const lastFat = +last[2]
    const firstFatMass = +(firstWeight * firstFat / 100).toFixed(2)
    const lastFatMass = +(lastWeight * lastFat / 100).toFixed(2)
    const goal = this.targetWeightValue

    const weightToGoal = goal ? +(lastWeight - goal).toFixed(2) : null
    const goalAchieved = goal && lastWeight <= goal

    const block = document.getElementById("goal-countdown-block")
    if (!block) return

    document.getElementById("first-weight").textContent = firstWeight.toFixed(2)
    document.getElementById("last-weight").textContent = lastWeight.toFixed(2)
    document.getElementById("first-fat").textContent = firstFat.toFixed(2)
    document.getElementById("last-fat").textContent = lastFat.toFixed(2)
    document.getElementById("first-fat-mass").textContent = firstFatMass.toFixed(2)
    document.getElementById("last-fat-mass").textContent = lastFatMass.toFixed(2)

    block.innerHTML = goal && lastWeight > 0
      ? (goalAchieved
        ? `<span class="text-xl font-bold text-violet-600">目標達成！！！</span>`
        : `<span>目標まであと</span>
           <span class="text-2xl font-bold text-gray-900 align-middle"
                 style="background: linear-gradient(transparent 60%, #fef08a 60%);">
             ${weightToGoal.toFixed(2)}
           </span>
           <span class="text-base font-bold text-gray-500">kg</span>`)
      : ""
  }

  /* ---------- タブ切り替え ---------- */
  initTabs() {
    this.tabGraphTarget.addEventListener("click", () => this.setMainTab("graph"))
    this.tabPhotoTarget.addEventListener("click", () => this.setMainTab("photo"))
  }

  setMainTab(active) {
    this.currentMainTab = active
    const on = ["bg-violet-500", "text-white"]
    const off = ["bg-violet-100", "text-violet-500"]

    if (active === "graph") {
      this.graphViewTarget.classList.remove("hidden")
      this.photoViewTarget.classList.add("hidden")
      if (this.hasPhotoSubTabsTarget) this.photoSubTabsTarget.classList.add("hidden")
      this.tabGraphTarget.classList.add(...on)
      this.tabGraphTarget.classList.remove(...off)
      this.tabPhotoTarget.classList.remove(...on)
      this.tabPhotoTarget.classList.add(...off)
      this.statsTableTarget.classList.remove("hidden")
      this.statsContentTarget.classList.remove("hidden")
      this.renderChart(this.currentPeriod)
    } else {
      this.graphViewTarget.classList.add("hidden")
      this.photoViewTarget.classList.remove("hidden")
      if (this.hasPhotoSubTabsTarget) this.photoSubTabsTarget.classList.remove("hidden")
      this.tabPhotoTarget.classList.add(...on)
      this.tabPhotoTarget.classList.remove(...off)
      this.tabGraphTarget.classList.remove(...on)
      this.tabGraphTarget.classList.add(...off)
      this.statsTableTarget.classList.add("hidden")
    }
  }

  initPeriodTabs() {
    this.periodTabTargets.forEach(btn => {
      btn.addEventListener("click", () => {
        this.currentPeriod = btn.dataset.period
        this.periodTabTargets.forEach(b => {
          b.classList.remove("bg-violet-500", "text-white")
          b.classList.add("bg-violet-100", "text-violet-600")
        })
        btn.classList.remove("bg-violet-100", "text-violet-600")
        btn.classList.add("bg-violet-500", "text-white")

        if (this.currentMainTab === "graph") {
          this.renderChart(btn.dataset.period)
          this.updateStatsTable(btn.dataset.period)
        } else {
          const el = document.querySelector('[data-controller="photo-switcher"]')
          if (el && el.StimulusController) {
            el.StimulusController.setPeriod(btn.dataset.period)
          }
          this.updateCompareView(btn.dataset.period)
        }
      })
    })
  }

  /* ---------- 写真タブ（レイヤー／比較） ---------- */
  setPhotoSubTab(event) {
    const tab = typeof event === "string"
      ? event
      : event.currentTarget?.dataset.tab

    if (!this.hasLayerTabTarget || !this.hasCompareTabTarget) return

    const on = ["bg-violet-500", "text-white"]
    const off = ["bg-violet-100", "text-violet-500"]

    if (tab === "layer") {
      this.layerTabTarget.classList.add(...on)
      this.layerTabTarget.classList.remove(...off)
      this.compareTabTarget.classList.remove(...on)
      this.compareTabTarget.classList.add(...off)
      this.layerViewTarget.classList.remove("hidden")
      this.compareViewTarget.classList.add("hidden")
    } else {
      this.layerTabTarget.classList.remove(...on)
      this.layerTabTarget.classList.add(...off)
      this.compareTabTarget.classList.add(...on)
      this.compareTabTarget.classList.remove(...off)
      this.layerViewTarget.classList.add("hidden")
      this.compareViewTarget.classList.remove("hidden")
      this.updateCompareView(this.currentPeriod)
    }
  }

  updateCompareView(period = "3m") {
    const el = document.querySelector('[data-controller="photo-switcher"]')
    if (!el) return
    const allPhotos = JSON.parse(el.dataset.photos)
    const placeholder = el.dataset.placeholder
    const now = new Date()
    let start = new Date(now)
    switch (period) {
      case "1w": start = new Date(now - 7 * 86400000); break
      case "3w": start = new Date(now - 21 * 86400000); break
      case "1m": start.setMonth(now.getMonth() - 1); break
      default: start.setMonth(now.getMonth() - 3)
    }

    const startStr = start.toISOString().slice(0, 10)
    const nowStr = now.toISOString().slice(0, 10)
    const filtered = allPhotos
      .slice()
      .sort((a, b) => a.date.localeCompare(b.date))
      .filter(p => p.date >= startStr && p.date <= nowStr)

    const beforeImg = document.getElementById("compare-before")
    const afterImg = document.getElementById("compare-after")

    if (filtered.length === 0) {
      beforeImg.src = afterImg.src = placeholder
    } else {
      beforeImg.src = filtered[0].url || placeholder
      afterImg.src = filtered[filtered.length - 1].url || placeholder
    }
  }
}
