/* ============ Progress Stats - 統計表更新機能 ============ */

function updateStatsTable(period) {
  // 期間の開始日を計算
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

  const graphView = document.getElementById("graph-view");
  if (!graphView) return;

  // 期間内のデータ抽出
  const records = (JSON.parse(graphView.dataset.progressAllRecordsValue) || []).filter(r => {
    const d = new Date(r[0]);
    return d >= start && d <= now && r[1] != null && r[2] != null;
  });

  // 最初・最後の値
  const first = records[0];
  const last = records[records.length - 1];

  const firstWeight = first ? Number(first[1]) : 0;
  const lastWeight = last ? Number(last[1]) : 0;
  const firstFat = first ? Number(first[2]) : 0;
  const lastFat = last ? Number(last[2]) : 0;
  const firstFatMass = first ? +(firstWeight * firstFat / 100).toFixed(2) : 0;
  const lastFatMass = last ? +(lastWeight * lastFat / 100).toFixed(2) : 0;

  // 目標体重までのカウントダウン
  let weightToGoal = 0;
  let goalAchieved = false;
  const targetWeight = JSON.parse(graphView.dataset.progressTargetWeightValue);
  if (targetWeight && lastWeight > 0) {
    if (lastWeight <= targetWeight) {
      weightToGoal = 0;
      goalAchieved = true;
    } else {
      weightToGoal = +(lastWeight - targetWeight).toFixed(2);
      goalAchieved = false;
    }
  }

  // 表の書き換え（要素の存在チェック付き）
  const firstWeightEl = document.getElementById('first-weight');
  const lastWeightEl = document.getElementById('last-weight');
  const firstFatEl = document.getElementById('first-fat');
  const lastFatEl = document.getElementById('last-fat');
  const firstFatMassEl = document.getElementById('first-fat-mass');
  const lastFatMassEl = document.getElementById('last-fat-mass');
  const block = document.getElementById('goal-countdown-block');

  // 要素が存在する場合のみ更新
  if (firstWeightEl) firstWeightEl.textContent = firstWeight.toFixed(2);
  if (lastWeightEl) lastWeightEl.textContent = lastWeight.toFixed(2);
  if (firstFatEl) firstFatEl.textContent = firstFat.toFixed(2);
  if (lastFatEl) lastFatEl.textContent = lastFat.toFixed(2);
  if (firstFatMassEl) firstFatMassEl.textContent = firstFatMass.toFixed(2);
  if (lastFatMassEl) lastFatMassEl.textContent = lastFatMass.toFixed(2);

  // カウントダウン・達成表示（要素の存在チェック付き）
  if (block) {
    // 目標体重が設定されている場合のみ表示
    if (targetWeight && lastWeight > 0) {
      if (goalAchieved) {
        block.innerHTML = '<span id="goal-achieved-label" class="text-xl font-bold text-violet-600">目標達成！！！</span>';
      } else {
        block.innerHTML = '<span id="goal-countdown-label">目標まであと</span>' +
          '<span id="goal-countdown-value" class="text-2xl font-bold text-gray-900 align-middle" style="background: linear-gradient(transparent 60%, #fef08a 60%);">' +
          weightToGoal.toFixed(2) +
          '</span>' +
          '<span id="goal-countdown-unit" class="text-base font-bold text-gray-500">kg</span>';
      }
    } else {
      // 目標体重が設定されていない場合は非表示
      block.innerHTML = '';
    }
  }
}

// 期間タブ切り替え時に表も更新
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
