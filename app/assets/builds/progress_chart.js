// app/javascript/classes/chart_config.js
var ChartConfig = class {
  constructor(isMobile = false) {
    this.isMobile = isMobile;
  }
  /**
   * Chart.jsの基本設定を返す
   * @param {Array} labels - X軸ラベル
   * @param {Array} weights - 体重データ
   * @param {Array} fats - 体脂肪率データ
   * @param {number} wMin - 体重Y軸最小値
   * @param {number} wMax - 体重Y軸最大値
   * @param {number} fMin - 体脂肪率Y軸最小値
   * @param {number} fMax - 体脂肪率Y軸最大値
   * @param {number|null} targetWeight - 目標体重
   * @returns {Object} Chart.js設定オブジェクト
   */
  getChartConfig(labels, weights, fats, wMin, wMax, fMin, fMax, targetWeight) {
    return {
      type: "line",
      data: {
        labels,
        datasets: this.#buildDatasets(weights, fats)
      },
      options: this.#buildOptions(wMin, wMax, fMin, fMax, targetWeight)
    };
  }
  /**
   * データセット設定を構築
   * @private
   */
  #buildDatasets(weights, fats) {
    return [
      {
        label: "\u4F53\u91CD(kg)",
        data: weights,
        borderColor: "rgba(255,99,132,0.9)",
        backgroundColor: "rgba(255,99,132,0.2)",
        spanGaps: true,
        yAxisID: "y1",
        borderWidth: this.isMobile ? 2 : 3,
        pointRadius: this.isMobile ? 3 : 4,
        pointHoverRadius: this.isMobile ? 5 : 6
      },
      {
        label: "\u4F53\u8102\u80AA\u7387(%)",
        data: fats,
        borderColor: "rgba(75,192,192,0.7)",
        backgroundColor: "rgba(75,192,192,0.2)",
        spanGaps: true,
        yAxisID: "y2",
        borderWidth: this.isMobile ? 2 : 3,
        pointRadius: this.isMobile ? 3 : 4,
        pointHoverRadius: this.isMobile ? 5 : 6
      }
    ];
  }
  /**
   * オプション設定を構築
   * @private
   */
  #buildOptions(wMin, wMax, fMin, fMax, targetWeight) {
    return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: this.#buildPlugins(targetWeight),
      scales: this.#buildScales(wMin, wMax, fMin, fMax)
    };
  }
  /**
   * プラグイン設定を構築
   * @private
   */
  #buildPlugins(targetWeight) {
    return {
      legend: {
        labels: {
          font: {
            size: this.isMobile ? 12 : 14
          }
        }
      },
      tooltip: {
        callbacks: {
          afterBody(context) {
            if (targetWeight) {
              return `\u76EE\u6A19\u4F53\u91CD: ${targetWeight}kg`;
            }
            return "";
          }
        }
      }
    };
  }
  /**
   * スケール設定を構築
   * @private
   */
  #buildScales(wMin, wMax, fMin, fMax) {
    return {
      x: {
        display: true,
        title: {
          display: true,
          text: "\u65E5\u4ED8",
          font: {
            size: this.isMobile ? 12 : 14
          }
        },
        ticks: {
          font: {
            size: this.isMobile ? 10 : 12
          },
          maxTicksLimit: this.isMobile ? 7 : 10
        }
      },
      y1: {
        type: "linear",
        position: "left",
        min: wMin,
        max: wMax,
        title: {
          display: true,
          text: "\u4F53\u91CD",
          font: {
            size: this.isMobile ? 12 : 14
          }
        },
        ticks: {
          font: {
            size: this.isMobile ? 10 : 12
          }
        }
      },
      y2: {
        type: "linear",
        position: "right",
        min: fMin,
        max: fMax,
        title: {
          display: true,
          text: "\u4F53\u8102\u80AA\u7387",
          font: {
            size: this.isMobile ? 12 : 14
          }
        },
        grid: { drawOnChartArea: false },
        ticks: {
          font: {
            size: this.isMobile ? 10 : 12
          }
        }
      }
    };
  }
  /**
   * 目標体重表示プラグインを作成
   * @param {HTMLElement} graphView - グラフビュー要素
   * @returns {Object} Chart.jsプラグイン
   */
  static createTargetWeightPlugin(graphView) {
    return {
      id: "customTargetWeight",
      afterDraw(chart, args, options) {
        const targetWeight = JSON.parse(graphView.dataset.progressTargetWeightValue);
        if (!targetWeight) return;
        const yScale = chart.scales.y1;
        const xScale = chart.scales.x;
        if (!yScale || !xScale) return;
        const weightData = chart.data.datasets.find((d) => d.label === "\u4F53\u91CD(kg)");
        if (!weightData || !weightData.data.some((d) => d !== null)) return;
        const y = yScale.getPixelForValue(targetWeight);
        const radius = window.innerWidth < 768 ? 10 : 12;
        const x = xScale.left - radius - 6;
        const ctx = chart.ctx;
        ctx.save();
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, 2 * Math.PI, false);
        ctx.fillStyle = "rgba(139, 92, 246, 0.7)";
        ctx.shadowColor = "rgba(139, 92, 246, 0.2)";
        ctx.shadowBlur = 2;
        ctx.fill();
        ctx.shadowBlur = 0;
        ctx.font = window.innerWidth < 768 ? "bold 10px sans-serif" : "bold 12px sans-serif";
        ctx.fillStyle = "#fff";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText(String(targetWeight), x, y);
        ctx.beginPath();
        ctx.setLineDash([5, 5]);
        ctx.strokeStyle = "rgba(139, 92, 246, 0.8)";
        ctx.lineWidth = 2;
        ctx.moveTo(x + radius, y);
        ctx.lineTo(chart.chartArea.right, y);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.restore();
      }
    };
  }
};

// app/javascript/classes/progress_graph.js
var ProgressGraph = class {
  constructor(graphViewElement) {
    this.graphView = graphViewElement;
    this.chart = null;
  }
  /**
   * グラフを描画
   * @param {string} period - 期間 ("1w", "3w", "1m", "3m")
   */
  render(period = "3m") {
    if (!this.graphView) return;
    this.#destroyExistingChart();
    this.#clearCanvas();
    const canvas = document.getElementById("weightChart");
    if (!canvas) return;
    const data = this.#buildData(period);
    const labels = this.#formatLabels(data);
    const weights = data.map((r) => r.weight);
    const fats = data.map((r) => r.fat);
    const { wMin, wMax, fMin, fMax } = this.#calculateScales(weights, fats);
    const targetWeight = this.#getTargetWeight();
    const isMobile = window.innerWidth < 768;
    const chartConfig = new ChartConfig(isMobile);
    const config = chartConfig.getChartConfig(
      labels,
      weights,
      fats,
      wMin,
      wMax,
      fMin,
      fMax,
      targetWeight
    );
    const ctx = canvas.getContext("2d");
    this.chart = new Chart(ctx, config);
    this.#setChartLabelRange(labels.length, period);
    this.#registerTargetWeightPlugin();
  }
  /**
   * グラフを破棄
   */
  destroy() {
    this.#destroyExistingChart();
  }
  /**
   * 既存チャートを破棄
   * @private
   */
  #destroyExistingChart() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
    if (typeof Chart !== "undefined" && Chart.helpers) {
      Chart.helpers.each(Chart.instances, (instance) => {
        instance.destroy();
      });
    }
  }
  /**
   * キャンバスをクリア
   * @private
   */
  #clearCanvas() {
    const canvas = document.getElementById("weightChart");
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  }
  /**
   * 期間に応じたデータを構築
   * @private
   */
  #buildData(period) {
    const now = /* @__PURE__ */ new Date();
    const start = this.#calculateStartDate(now, period);
    const range = this.#generateDateRange(start, now);
    const map = this.#createDataMap();
    return range.map((d) => ({
      label: d,
      weight: map[d]?.w ?? null,
      fat: map[d]?.f ?? null
    }));
  }
  /**
   * 開始日を計算
   * @private
   */
  #calculateStartDate(now, period) {
    const start = new Date(now);
    switch (period) {
      case "1w":
        return new Date(now.getTime() - 7 * 864e5);
      case "3w":
        return new Date(now.getTime() - 21 * 864e5);
      case "1m":
        start.setMonth(now.getMonth() - 1);
        return start;
      case "3m":
      default:
        start.setMonth(now.getMonth() - 3);
        return start;
    }
  }
  /**
   * 日付範囲を生成
   * @private
   */
  #generateDateRange(start, end) {
    const arr = [];
    const cur = new Date(start);
    while (cur <= end) {
      const y = cur.getFullYear();
      const m = String(cur.getMonth() + 1).padStart(2, "0");
      const d = String(cur.getDate()).padStart(2, "0");
      arr.push(`${y}-${m}-${d}`);
      cur.setDate(cur.getDate() + 1);
    }
    return arr;
  }
  /**
   * データマップを作成
   * @private
   */
  #createDataMap() {
    const labels = JSON.parse(this.graphView.dataset.progressLabelsValue);
    const weights = JSON.parse(this.graphView.dataset.progressWeightsValue);
    const fats = JSON.parse(this.graphView.dataset.progressFatRatesValue);
    const map = {};
    labels.forEach((d, i) => {
      map[d] = { w: +weights[i], f: +fats[i] };
    });
    return map;
  }
  /**
   * ラベルをフォーマット
   * @private
   */
  #formatLabels(data) {
    const isMobile = window.innerWidth < 768;
    return data.map((r) => {
      const t = new Date(r.label);
      return isMobile ? `${t.getMonth() + 1}/${t.getDate()}` : `${t.getMonth() + 1}/${t.getDate()}`;
    });
  }
  /**
   * スケール範囲を計算
   * @private
   */
  #calculateScales(weights, fats) {
    const vw = weights.filter((v) => v !== null);
    const vf = fats.filter((v) => v !== null);
    const fMin = vf.length ? Math.floor(Math.min(...vf)) - 5 : void 0;
    const fMax = vf.length ? Math.ceil(Math.max(...vf)) + 5 : void 0;
    let wMin = vw.length ? Math.floor(Math.min(...vw)) - 5 : void 0;
    let wMax = vw.length ? Math.ceil(Math.max(...vw)) + 5 : void 0;
    const targetWeight = this.#getTargetWeight();
    if (targetWeight && vw.length > 0) {
      const currentMin = Math.min(...vw);
      const currentMax = Math.max(...vw);
      if (targetWeight < currentMin) {
        wMin = Math.floor(targetWeight) - 5;
        wMax = Math.ceil(currentMax) + 5;
      } else if (targetWeight > currentMax) {
        wMin = Math.floor(currentMin) - 5;
        wMax = Math.ceil(targetWeight) + 5;
      }
    }
    return { wMin, wMax, fMin, fMax };
  }
  /**
   * 目標体重を取得
   * @private
   */
  #getTargetWeight() {
    return JSON.parse(this.graphView.dataset.progressTargetWeightValue);
  }
  /**
   * チャートラベル範囲を設定
   * @private
   */
  #setChartLabelRange(dataLength, period) {
    if (!this.chart) return;
    const { maxDisplay, minDisplay } = this.#calculateDisplayRange(dataLength, period);
    if (dataLength <= maxDisplay) {
      this.chart.options.scales.x.ticks = {
        min: 0,
        max: dataLength - 1
      };
    } else {
      this.chart.options.scales.x.ticks = {
        min: minDisplay,
        max: maxDisplay - 1
      };
    }
    this.chart.update();
  }
  /**
   * 表示範囲を計算
   * @private
   */
  #calculateDisplayRange(dataLength, period) {
    let maxDisplay, minDisplay;
    switch (period) {
      case "1w":
        maxDisplay = Math.min(dataLength, 7);
        minDisplay = Math.max(0, dataLength - 7);
        break;
      case "3w":
        maxDisplay = Math.min(dataLength, 21);
        minDisplay = Math.max(0, dataLength - 21);
        break;
      case "1m":
        maxDisplay = Math.min(dataLength, 30);
        minDisplay = Math.max(0, dataLength - 30);
        break;
      case "3m":
      default:
        maxDisplay = Math.min(dataLength, 90);
        minDisplay = Math.max(0, dataLength - 90);
        break;
    }
    return { maxDisplay, minDisplay };
  }
  /**
   * 目標体重プラグインを登録
   * @private
   */
  #registerTargetWeightPlugin() {
    const plugin = ChartConfig.createTargetWeightPlugin(this.graphView);
    Chart.register(plugin);
  }
};

// app/javascript/progress_chart.js
var progressGraphInstance = null;
function renderChart(period = "3m") {
  const graphView = document.getElementById("graph-view");
  if (!graphView) return;
  if (progressGraphInstance) {
    progressGraphInstance.destroy();
  }
  progressGraphInstance = new ProgressGraph(graphView);
  progressGraphInstance.render(period);
  window.chart = progressGraphInstance.chart;
}
window.renderChart = renderChart;
//# sourceMappingURL=/assets/progress_chart.js.map
