/* ============ Progress Stats - 統計表更新機能 ============ */

import { ProgressStats } from './classes/progress_stats.js';

// グローバル統計インスタンス
let progressStatsInstance = null;

/**
 * 統計表を更新
 * @param {string} period - 期間 ("1w", "3w", "1m", "3m")
 */
function updateStatsTable(period) {
  const graphView = document.getElementById("graph-view");
  if (!graphView) return;

  // インスタンスがなければ作成
  if (!progressStatsInstance) {
    progressStatsInstance = new ProgressStats(graphView);
  }

  // 統計を更新
  progressStatsInstance.update(period);
}

/**
 * 期間タブ切り替え時に表も更新
 */
function patchPeriodTabEvents() {
  document.querySelectorAll('.period-tab').forEach(btn => {
    btn.addEventListener('click', () => {
      updateStatsTable(btn.dataset.period);
    });
  });
}

// グローバルにエクスポート
window.updateStatsTable = updateStatsTable;
window.patchPeriodTabEvents = patchPeriodTabEvents;
