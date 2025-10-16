/* ============ Progress Page - ページ初期化機能 ============ */

/* ============ ページ初期化関数 ============== */
function initGraphPage() {
  // 必要な要素が存在するかチェック
  const graphView = document.getElementById("graph-view");
  const photoView = document.getElementById("photo-view");
  const tabGraph = document.getElementById("tab-graph");
  const tabPhoto = document.getElementById("tab-photo");
  const weightChart = document.getElementById("weightChart");

  // 必要な要素が存在しない場合は早期終了
  if (!graphView || !photoView || !tabGraph || !tabPhoto || !weightChart) {
    return;
  }

  // どちらのタブを初期表示するか判定
  const initialTab = (window.activeTab === "photo") ? "photo" : "graph";
  if (initialTab === "photo") {
    graphView.classList.add("hidden");
    photoView.classList.remove("hidden");
    setMainTab("photo");
    // 統計表を非表示
    document.getElementById("stats-table").classList.add("hidden");
  } else {
    graphView.classList.remove("hidden");
    photoView.classList.add("hidden");
    setMainTab("graph");
    // 統計表を表示
    document.getElementById("stats-table").classList.remove("hidden");
    document.getElementById("stats-content").classList.remove("hidden");
  }

  // グラブビューの期間タブを初期化
  document.querySelectorAll("#graph-view .period-tab").forEach(btn => {
    if (btn.dataset.period === "3m") {
      btn.classList.add("bg-violet-500", "text-white");
      btn.classList.remove("bg-violet-100", "text-violet-600");
    } else {
      btn.classList.remove("bg-violet-500", "text-white");
      btn.classList.add("bg-violet-100", "text-violet-600");
    }
  });

  // 写真ビューの期間タブも初期化
  document.querySelectorAll("#photo-view .period-tab").forEach(btn => {
    btn.classList.remove("bg-violet-500", "text-white");
    btn.classList.add("bg-violet-100", "text-violet-600");
  });
  const photo3m = document.querySelector('#photo-view .period-tab[data-period="3m"]');
  if (photo3m) {
    photo3m.classList.remove("bg-violet-100", "text-violet-600");
    photo3m.classList.add("bg-violet-500", "text-white");
  }

  // 既存のChart.jsインスタンスをクリア
  if (typeof Chart !== 'undefined' && Chart.helpers) {
    Chart.helpers.each(Chart.instances, (instance) => {
      instance.destroy();
    });
  }

  if (window.chart) {
    window.chart.destroy();
    window.chart = null;
  }

  /* ---- タブ切替（グラフ/写真） ---------------- */
  function setMainTab(active) {
    const on = "w-full bg-violet-500 text-white py-2 rounded text-xs sm:text-sm";
    const off = "w-full bg-violet-100 text-violet-500 py-2 rounded text-xs sm:text-sm";
    tabGraph.className = active === "graph" ? on : off;
    tabPhoto.className = active === "photo" ? on : off;
  }

  tabGraph.onclick = () => {
    graphView.classList.remove("hidden");
    photoView.classList.add("hidden");
    setMainTab("graph");
    // 統計表を表示
    document.getElementById("stats-table").classList.remove("hidden");
    document.getElementById("stats-content").classList.remove("hidden");
    // 期間ボタンを3ヶ月にリセット
    document.querySelectorAll("#graph-view .period-tab").forEach(btn => {
      if (btn.dataset.period === "3m") {
        btn.classList.add("bg-violet-500", "text-white");
        btn.classList.remove("bg-violet-100", "text-violet-600");
      } else {
        btn.classList.remove("bg-violet-500", "text-white");
        btn.classList.add("bg-violet-100", "text-violet-600");
      }
    });
    if (window.renderChart) {
      window.renderChart("3m");
    }
  };

  tabPhoto.onclick = () => {
    graphView.classList.add("hidden");
    photoView.classList.remove("hidden");
    setMainTab("photo");
    // 統計表を非表示
    document.getElementById("stats-table").classList.add("hidden");
    // 期間ボタンを3ヶ月にリセット
    document.querySelectorAll("#photo-view .period-tab").forEach(btn => {
      if (btn.dataset.period === "3m") {
        btn.classList.add("bg-violet-500", "text-white");
        btn.classList.remove("bg-violet-100", "text-violet-600");
      } else {
        btn.classList.remove("bg-violet-500", "text-white");
        btn.classList.add("bg-violet-100", "text-violet-600");
      }
    });
    // Stimulusコントローラーで3mにリセット
    const photoSwitcher = document.querySelector('[data-controller="photo-switcher"]');
    if (photoSwitcher?.controller) {
      if (typeof photoSwitcher.controller.setPeriod === 'function') {
        photoSwitcher.controller.setPeriod("3m");
      }
    } else if (window.application && window.application.getControllerForElementAndIdentifier) {
      // Stimulus v3以降の取得方法
      const controller = window.application.getControllerForElementAndIdentifier(photoSwitcher, "photo-switcher");
      if (controller && typeof controller.setPeriod === 'function') {
        controller.setPeriod("3m");
      }
    }
  };

  /* ---- 期間ボタン ------------------------------ */
  document.querySelectorAll(".period-tab").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".period-tab").forEach(b => {
        b.classList.remove("bg-violet-500", "text-white");
        b.classList.add("bg-violet-100", "text-violet-600");
      });
      btn.classList.remove("bg-violet-100", "text-violet-600");
      btn.classList.add("bg-violet-500", "text-white");
      if (window.renderChart) {
        window.renderChart(btn.dataset.period);
      }
    });
  });

  // 初期表示
  if (window.renderChart) {
    window.renderChart("3m");
  }

  // リサイズ時の対応
  window.addEventListener('resize', () => {
    if (window.chart && window.renderChart) {
      window.renderChart(document.querySelector('.period-tab.bg-violet-500')?.dataset.period || '3m');
    }
  });
}

/* --------- イベント登録 (Turbo対応) ---------- */
document.addEventListener("turbo:load", initGraphPage);

// 統計表の初期化とイベント登録
document.addEventListener("DOMContentLoaded", () => {
  if (window.updateStatsTable) {
    window.updateStatsTable('3m');
  }
  if (window.patchPeriodTabEvents) {
    window.patchPeriodTabEvents();
  }
});

document.addEventListener("turbo:load", () => {
  if (window.updateStatsTable) {
    window.updateStatsTable('3m');
  }
  if (window.patchPeriodTabEvents) {
    window.patchPeriodTabEvents();
  }
});
