/* ============ ChartConfig - Chart.js設定クラス ============ */

export class ChartConfig {
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
        label: "体重(kg)",
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
        label: "体脂肪率(%)",
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
              return `目標体重: ${targetWeight}kg`;
            }
            return '';
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
          text: "日付",
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
          text: "体重",
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
          text: "体脂肪率",
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
      id: 'customTargetWeight',
      afterDraw(chart, args, options) {
        const targetWeight = JSON.parse(graphView.dataset.progressTargetWeightValue);
        if (!targetWeight) return;

        const yScale = chart.scales.y1;
        const xScale = chart.scales.x;
        if (!yScale || !xScale) return;

        const weightData = chart.data.datasets.find(d => d.label === "体重(kg)");
        if (!weightData || !weightData.data.some(d => d !== null)) return;

        const y = yScale.getPixelForValue(targetWeight);
        const radius = window.innerWidth < 768 ? 10 : 12;
        const x = xScale.left - radius - 6;
        const ctx = chart.ctx;

        ctx.save();
        // 丸を描画
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, 2 * Math.PI, false);
        ctx.fillStyle = 'rgba(139, 92, 246, 0.7)';
        ctx.shadowColor = 'rgba(139, 92, 246, 0.2)';
        ctx.shadowBlur = 2;
        ctx.fill();
        ctx.shadowBlur = 0;

        // 数字を描画
        ctx.font = (window.innerWidth < 768 ? 'bold 10px sans-serif' : 'bold 12px sans-serif');
        ctx.fillStyle = '#fff';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(String(targetWeight), x, y);

        // 破線を描画
        ctx.beginPath();
        ctx.setLineDash([5, 5]);
        ctx.strokeStyle = 'rgba(139, 92, 246, 0.8)';
        ctx.lineWidth = 2;
        ctx.moveTo(x + radius, y);
        ctx.lineTo(chart.chartArea.right, y);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.restore();
      }
    };
  }
}
