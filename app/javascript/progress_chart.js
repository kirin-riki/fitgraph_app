/* ============ Progress Chart - グラフ描画機能 ============ */

/* -------- 共通ユーティリティ -------- */
function generateDateRange(start, end) {
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

/* ============ 横軸範囲制御関数 ============== */
function setChartLabel(dataLength, chartInstance, period) {
  // データ数に応じて横軸の表示範囲を制御
  let maxDisplay;
  let minDisplay;

  switch (period) {
    case "1w":
      // 1週間の場合は最大7日分表示
      maxDisplay = Math.min(dataLength, 7);
      minDisplay = Math.max(0, dataLength - 7);
      break;
    case "3w":
      // 3週間の場合は最大21日分表示
      maxDisplay = Math.min(dataLength, 21);
      minDisplay = Math.max(0, dataLength - 21);
      break;
    case "1m":
      // 1ヶ月の場合は最大30日分表示
      maxDisplay = Math.min(dataLength, 30);
      minDisplay = Math.max(0, dataLength - 30);
      break;
    case "3m":
    default:
      // 3ヶ月の場合は最大90日分表示
      maxDisplay = Math.min(dataLength, 90);
      minDisplay = Math.max(0, dataLength - 90);
      break;
  }

  // データが少ない場合は全表示
  if (dataLength <= maxDisplay) {
    chartInstance.options.scales.x.ticks = {
      min: 0,
      max: dataLength - 1
    };
  } else {
    // データが多い場合は最新の範囲を表示
    chartInstance.options.scales.x.ticks = {
      min: minDisplay,
      max: maxDisplay - 1
    };
  }

  // チャートを更新
  chartInstance.update();
}

/* ============ グラフ描画関数 ============== */
function buildData(period, graphView) {
  const now = new Date();
  let start = new Date(now);
  switch (period) {
    case "1w":
      start = new Date(now.getTime() - 7 * 86400000);
      break;
    case "3w":
      start = new Date(now.getTime() - 21 * 86400000);
      break;
    case "1m":
      start.setMonth(now.getMonth() - 1);
      break;
    case "3m":
    default:
      start.setMonth(now.getMonth() - 3);
      break;
  }
  const range = generateDateRange(start, now);
  const map = {};
  // データはStimulusコントローラのdata属性から取得
  const labels = JSON.parse(graphView.dataset.progressLabelsValue);
  const weights = JSON.parse(graphView.dataset.progressWeightsValue);
  const fats = JSON.parse(graphView.dataset.progressFatRatesValue);

  labels.forEach((d, i) => {
    map[d] = { w: +weights[i], f: +fats[i] };
  });
  return range.map(d => ({
    label: d,
    weight: map[d]?.w ?? null,
    fat: map[d]?.f ?? null
  }));
}

function renderChart(period = "3m") {
  const graphView = document.getElementById("graph-view");
  if (!graphView) return;

  // 既存チャートがあれば破棄
  if (window.chart) {
    window.chart.destroy();
    window.chart = null;
  }

  // すべてのChart.jsインスタンスを破棄
  if (typeof Chart !== 'undefined' && Chart.helpers) {
    Chart.helpers.each(Chart.instances, (instance) => {
      instance.destroy();
    });
  }

  // canvas要素をリセット
  const canvas = document.getElementById("weightChart");
  if (!canvas) return;

  const ctx = canvas.getContext("2d");
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  const rows = buildData(period, graphView);
  const labels = rows.map(r => {
    const t = new Date(r.label);
    // スマホでは日付を短縮表示
    const isMobile = window.innerWidth < 768;
    return isMobile ? `${t.getMonth() + 1}/${t.getDate()}` : `${t.getMonth() + 1}/${t.getDate()}`;
  });
  const weights = rows.map(r => r.weight);
  const fats = rows.map(r => r.fat);

  // 最大・最小インデックスを計算
  const vw = weights.filter(v => v !== null);
  const vf = fats.filter(v => v !== null);

  const fMin = vf.length ? Math.floor(Math.min(...vf)) - 5 : undefined;
  const fMax = vf.length ? Math.ceil(Math.max(...vf)) + 5 : undefined;

  // 目標体重の表示条件とスケール調整
  let wMin = vw.length ? Math.floor(Math.min(...vw)) - 5 : undefined;
  let wMax = vw.length ? Math.ceil(Math.max(...vw)) + 5 : undefined;

  // 目標体重が設定されている場合の処理
  const targetWeight = JSON.parse(graphView.dataset.progressTargetWeightValue);
  if (targetWeight && vw.length > 0) {
    const currentMin = Math.min(...vw);
    const currentMax = Math.max(...vw);

    // 目標体重が現在の範囲外の場合、範囲に含めるように調整
    if (targetWeight < currentMin) {
      // 目標体重が最小値より小さい場合、最小値側にスケールを寄せる
      wMin = Math.floor(targetWeight) - 5;
      wMax = Math.ceil(currentMax) + 5;
    } else if (targetWeight > currentMax) {
      // 目標体重が最大値より大きい場合、最大値側にスケールを寄せる
      wMin = Math.floor(currentMin) - 5;
      wMax = Math.ceil(targetWeight) + 5;
    }
    // 目標体重が範囲内の場合は何もしない（既存の範囲を使用）
  }

  // スマホ判定
  const isMobile = window.innerWidth < 768;

  // 体重・体脂肪率の点表示をすべての点で表示（元の仕様）
  // 新チャートを生成
  window.chart = new Chart(ctx, {
    type: "line",
    data: {
      labels,
      datasets: [
        {
          label: "体重(kg)",
          data: weights,
          borderColor: "rgba(255,99,132,0.9)",
          backgroundColor: "rgba(255,99,132,0.2)",
          spanGaps: true,
          yAxisID: "y1",
          borderWidth: isMobile ? 2 : 3,
          pointRadius: isMobile ? 3 : 4,
          pointHoverRadius: isMobile ? 5 : 6
        },
        {
          label: "体脂肪率(%)",
          data: fats,
          borderColor: "rgba(75,192,192,0.7)",
          backgroundColor: "rgba(75,192,192,0.2)",
          spanGaps: true,
          yAxisID: "y2",
          borderWidth: isMobile ? 2 : 3,
          pointRadius: isMobile ? 3 : 4,
          pointHoverRadius: isMobile ? 5 : 6
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          labels: {
            font: {
              size: isMobile ? 12 : 14
            }
          }
        },
        tooltip: {
          callbacks: {
            afterBody(context) {
              // 目標体重が設定されている場合のみ表示
              const targetWeight = JSON.parse(graphView.dataset.progressTargetWeightValue);
              if (targetWeight) {
                return `目標体重: ${targetWeight}kg`;
              }
              return '';
            }
          }
        }
      },
      scales: {
        x: {
          display: true,
          title: {
            display: true,
            text: "日付",
            font: {
              size: isMobile ? 12 : 14
            }
          },
          ticks: {
            font: {
              size: isMobile ? 10 : 12
            },
            maxTicksLimit: isMobile ? 7 : 10
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
              size: isMobile ? 12 : 14
            }
          },
          ticks: {
            font: {
              size: isMobile ? 10 : 12
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
              size: isMobile ? 12 : 14
            }
          },
          grid: { drawOnChartArea: false },
          ticks: {
            font: {
              size: isMobile ? 10 : 12
            }
          }
        }
      }
    }
  });

  // 横軸範囲制御
  setChartLabel(labels.length, window.chart, period);

  // Chart.jsカスタムプラグイン: 目標体重の丸＋数値
  Chart.register({
    id: 'customTargetWeight',
    afterDraw(chart, args, options) {
      // 目標体重が設定されていない場合は表示しない
      const targetWeight = JSON.parse(graphView.dataset.progressTargetWeightValue);
      if (!targetWeight) return;

      // 身体情報のデータが存在しない場合は表示しない
      const yScale = chart.scales.y1;
      const xScale = chart.scales.x;
      if (!yScale || !xScale) return;

      // 体重データが存在しない場合は表示しない
      const weightData = chart.data.datasets.find(d => d.label === "体重(kg)");
      if (!weightData || !weightData.data.some(d => d !== null)) return;

      const y = yScale.getPixelForValue(targetWeight);
      const radius = window.innerWidth < 768 ? 10 : 12;
      const x = xScale.left - radius - 6;
      const ctx = chart.ctx;
      ctx.save();
      // 丸
      ctx.beginPath();
      ctx.arc(x, y, radius, 0, 2 * Math.PI, false);
      ctx.fillStyle = 'rgba(139, 92, 246, 0.7)';
      ctx.shadowColor = 'rgba(139, 92, 246, 0.2)';
      ctx.shadowBlur = 2;
      ctx.fill();
      ctx.shadowBlur = 0;
      // 数字
      ctx.font = (window.innerWidth < 768 ? 'bold 10px sans-serif' : 'bold 12px sans-serif');
      ctx.fillStyle = '#fff';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(String(targetWeight), x, y);
      // 破線
      ctx.beginPath();
      ctx.setLineDash([5, 5]);
      ctx.strokeStyle = 'rgba(139, 92, 246, 0.8)';
      ctx.lineWidth = 2;
      ctx.moveTo(x + radius, y); // 円の右端から
      ctx.lineTo(chart.chartArea.right, y); // グラフ右端まで
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();
    }
  });
}

// グローバルにエクスポート
window.renderChart = renderChart;
