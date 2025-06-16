// app/javascript/controllers/camera_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "previewContainer",
    "canvas",
    "placeholder",
    "shootButton",
    "fileInput"
  ];

  connect() {
    // ファイル選択時プレビュー
    this.fileInputTarget.addEventListener("change", this.previewUpload.bind(this));

    // 簡易スマホ判定
    const isMobile =
      /Mobi|Android|iPhone|iPad|iPod/.test(navigator.userAgent) &&
      navigator.mediaDevices?.getUserMedia;

    if (!isMobile) {
      // PCや未対応環境ではカメラボタンを隠す
      this.shootButtonTarget.classList.add("hidden");
    }
  }

  shoot() {
    if (!this.video) {
      // まだ起動していなければカメラ起動
      this._startCamera();
      this.shootButtonTarget.textContent = "撮影";
    } else {
      // 既に起動済みならキャプチャ
      this._capture();
    }
  }

  _startCamera() {
    navigator.mediaDevices.getUserMedia({ video: true })
      .then(stream => {
        this.video = document.createElement("video");
        this.video.srcObject = stream;
        this.video.play();
        this.previewContainerTarget.innerHTML = "";
        this.previewContainerTarget.appendChild(this.video);
      })
      .catch(err => {
        console.error("カメラ起動に失敗:", err);
        // 必要ならユーザーに通知を出しても良い
      });
  }

  _capture() {
    const canvas = this.canvasTarget;
    const ctx = canvas.getContext("2d");

    // 描画・プレビュー切り替え
    ctx.drawImage(this.video, 0, 0, canvas.width, canvas.height);
    canvas.classList.remove("hidden");
    this.video.remove();
    this.placeholderTarget?.remove();

    // ボタン文言をリセット or 再撮影に変更
    this.shootButtonTarget.textContent = "再撮影";

    // Blob → file_field にセット
    canvas.toBlob(blob => {
      const file = new File([blob], "photo.jpg", { type: "image/jpeg" });
      const dt = new DataTransfer();
      dt.items.add(file);
      this.fileInputTarget.files = dt.files;
    }, "image/jpeg", 0.8);
  }

  previewUpload(event) {
    // ファイル選択時のプレビュー更新
    const file = event.target.files[0];
    if (!file) return;

    const url = URL.createObjectURL(file);
    this.previewContainerTarget.innerHTML = `
      <img src="${url}" width="240" height="336" class="rounded" />
    `;
    this.video?.remove();
    this.canvasTarget.classList.add("hidden");
    this.placeholderTarget?.remove();
    this.shootButtonTarget.textContent = "再撮影";
  }
}
