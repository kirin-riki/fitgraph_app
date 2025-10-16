// app/javascript/classes/progress_stats.js
var ProgressStats = class {
  constructor(graphViewElement) {
    this.graphView = graphViewElement;
  }
  /**
   * 統計表を更新
   * @param {string} period - 期間 ("1w", "3w", "1m", "3m")
   */
  update(period) {
    if (!this.graphView) return;
    const { start, end } = this.#calculatePeriodRange(period);
    const records = this.#filterRecordsByPeriod(start, end);
    if (records.length === 0) {
      this.#updateEmptyStats();
      return;
    }
    const stats = this.#calculateStats(records);
    this.#updateDisplay(stats);
  }
  /**
   * 期間範囲を計算
   * @private
   */
  #calculatePeriodRange(period) {
    const now = /* @__PURE__ */ new Date();
    const start = new Date(now);
    switch (period) {
      case "1w":
        start.setTime(now.getTime() - 7 * 864e5);
        break;
      case "3w":
        start.setTime(now.getTime() - 21 * 864e5);
        break;
      case "1m":
        start.setMonth(now.getMonth() - 1);
        break;
      case "3m":
      default:
        start.setMonth(now.getMonth() - 3);
        break;
    }
    return { start, end: now };
  }
  /**
   * 期間内のレコードをフィルタ
   * @private
   */
  #filterRecordsByPeriod(start, end) {
    const allRecords = JSON.parse(this.graphView.dataset.progressAllRecordsValue) || [];
    return allRecords.filter((r) => {
      const d = new Date(r[0]);
      return d >= start && d <= end && r[1] != null && r[2] != null;
    });
  }
  /**
   * 統計を計算
   * @private
   */
  #calculateStats(records) {
    const first = records[0];
    const last = records[records.length - 1];
    const firstWeight = first ? Number(first[1]) : 0;
    const lastWeight = last ? Number(last[1]) : 0;
    const firstFat = first ? Number(first[2]) : 0;
    const lastFat = last ? Number(last[2]) : 0;
    const firstFatMass = first ? +(firstWeight * firstFat / 100).toFixed(2) : 0;
    const lastFatMass = last ? +(lastWeight * lastFat / 100).toFixed(2) : 0;
    const { weightToGoal, goalAchieved } = this.#calculateGoalProgress(lastWeight);
    return {
      firstWeight,
      lastWeight,
      firstFat,
      lastFat,
      firstFatMass,
      lastFatMass,
      weightToGoal,
      goalAchieved
    };
  }
  /**
   * 目標までの進捗を計算
   * @private
   */
  #calculateGoalProgress(lastWeight) {
    const targetWeight = JSON.parse(this.graphView.dataset.progressTargetWeightValue);
    if (!targetWeight || lastWeight === 0) {
      return { weightToGoal: 0, goalAchieved: false };
    }
    if (lastWeight <= targetWeight) {
      return { weightToGoal: 0, goalAchieved: true };
    }
    return {
      weightToGoal: +(lastWeight - targetWeight).toFixed(2),
      goalAchieved: false
    };
  }
  /**
   * 表示を更新
   * @private
   */
  #updateDisplay(stats) {
    this.#updateWeights(stats.firstWeight, stats.lastWeight);
    this.#updateFats(stats.firstFat, stats.lastFat);
    this.#updateFatMasses(stats.firstFatMass, stats.lastFatMass);
    this.#updateGoalCountdown(stats.weightToGoal, stats.goalAchieved);
  }
  /**
   * 体重表示を更新
   * @private
   */
  #updateWeights(first, last) {
    this.#updateElement("first-weight", first.toFixed(2));
    this.#updateElement("last-weight", last.toFixed(2));
  }
  /**
   * 体脂肪率表示を更新
   * @private
   */
  #updateFats(first, last) {
    this.#updateElement("first-fat", first.toFixed(2));
    this.#updateElement("last-fat", last.toFixed(2));
  }
  /**
   * 脂肪量表示を更新
   * @private
   */
  #updateFatMasses(first, last) {
    this.#updateElement("first-fat-mass", first.toFixed(2));
    this.#updateElement("last-fat-mass", last.toFixed(2));
  }
  /**
   * 目標カウントダウン表示を更新
   * @private
   */
  #updateGoalCountdown(weightToGoal, goalAchieved) {
    const block = document.getElementById("goal-countdown-block");
    if (!block) return;
    const targetWeight = JSON.parse(this.graphView.dataset.progressTargetWeightValue);
    if (!targetWeight || weightToGoal === 0 && !goalAchieved) {
      block.innerHTML = "";
      return;
    }
    if (goalAchieved) {
      block.innerHTML = '<span id="goal-achieved-label" class="text-xl font-bold text-violet-600">\u76EE\u6A19\u9054\u6210\uFF01\uFF01\uFF01</span>';
    } else {
      block.innerHTML = `
        <span id="goal-countdown-label">\u76EE\u6A19\u307E\u3067\u3042\u3068</span>
        <span id="goal-countdown-value" class="text-2xl font-bold text-gray-900 align-middle" style="background: linear-gradient(transparent 60%, #fef08a 60%);">
          ${weightToGoal.toFixed(2)}
        </span>
        <span id="goal-countdown-unit" class="text-base font-bold text-gray-500">kg</span>
      `;
    }
  }
  /**
   * 要素のテキストを更新
   * @private
   */
  #updateElement(id, text) {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
  }
  /**
   * 空の統計を表示
   * @private
   */
  #updateEmptyStats() {
    this.#updateDisplay({
      firstWeight: 0,
      lastWeight: 0,
      firstFat: 0,
      lastFat: 0,
      firstFatMass: 0,
      lastFatMass: 0,
      weightToGoal: 0,
      goalAchieved: false
    });
  }
};

// app/javascript/progress_stats.js
var progressStatsInstance = null;
function updateStatsTable(period) {
  const graphView = document.getElementById("graph-view");
  if (!graphView) return;
  if (!progressStatsInstance) {
    progressStatsInstance = new ProgressStats(graphView);
  }
  progressStatsInstance.update(period);
}
function patchPeriodTabEvents() {
  document.querySelectorAll(".period-tab").forEach((btn) => {
    btn.addEventListener("click", () => {
      updateStatsTable(btn.dataset.period);
    });
  });
}
window.updateStatsTable = updateStatsTable;
window.patchPeriodTabEvents = patchPeriodTabEvents;
//# sourceMappingURL=/assets/progress_stats.js.map
