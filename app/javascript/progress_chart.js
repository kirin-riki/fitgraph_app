/* ============ Progress Chart - グラフ描画機能 ============ */

import { ProgressGraph } from './classes/progress_graph.js';

// グローバルグラフインスタンス
let progressGraphInstance = null;

/**
 * グラフを描画
 * @param {string} period - 期間 ("1w", "3w", "1m", "3m")
 */
function renderChart(period = "3m") {
  const graphView = document.getElementById("graph-view");
  if (!graphView) return;

  // 既存インスタンスがあれば破棄
  if (progressGraphInstance) {
    progressGraphInstance.destroy();
  }

  // 新しいインスタンスを作成して描画
  progressGraphInstance = new ProgressGraph(graphView);
  progressGraphInstance.render(period);

  // グローバルに保存（リサイズ対応のため）
  window.chart = progressGraphInstance.chart;
}

// グローバルにエクスポート
window.renderChart = renderChart;
