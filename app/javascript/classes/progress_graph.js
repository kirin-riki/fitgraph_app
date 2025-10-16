/* ============ ProgressGraph - グラフ描画クラス ============ */

import { ChartConfig } from './chart_config.js';

export class ProgressGraph {
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
    const weights = data.map(r => r.weight);
    const fats = data.map(r => r.fat);

    const { wMin, wMax, fMin, fMax } = this.#calculateScales(weights, fats);
    const targetWeight = this.#getTargetWeight();

    const isMobile = window.innerWidth < 768;
    const chartConfig = new ChartConfig(isMobile);
    const config = chartConfig.getChartConfig(
      labels, weights, fats, wMin, wMax, fMin, fMax, targetWeight
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

    if (typeof Chart !== 'undefined' && Chart.helpers) {
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
    const now = new Date();
    const start = this.#calculateStartDate(now, period);
    const range = this.#generateDateRange(start, now);

    const map = this.#createDataMap();

    return range.map(d => ({
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
        return new Date(now.getTime() - 7 * 86400000);
      case "3w":
        return new Date(now.getTime() - 21 * 86400000);
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

    return data.map(r => {
      const t = new Date(r.label);
      return isMobile ? `${t.getMonth() + 1}/${t.getDate()}` : `${t.getMonth() + 1}/${t.getDate()}`;
    });
  }

  /**
   * スケール範囲を計算
   * @private
   */
  #calculateScales(weights, fats) {
    const vw = weights.filter(v => v !== null);
    const vf = fats.filter(v => v !== null);

    const fMin = vf.length ? Math.floor(Math.min(...vf)) - 5 : undefined;
    const fMax = vf.length ? Math.ceil(Math.max(...vf)) + 5 : undefined;

    let wMin = vw.length ? Math.floor(Math.min(...vw)) - 5 : undefined;
    let wMax = vw.length ? Math.ceil(Math.max(...vw)) + 5 : undefined;

    // 目標体重を考慮したスケール調整
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
}
