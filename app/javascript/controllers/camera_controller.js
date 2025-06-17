// app/javascript/controllers/camera_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "previewContainer",
    "placeholder",
    "nativeCameraButton",
    "nativeCameraInput",
    "fileInput"
  ];

  connect() {
    // ファイル選択時プレビュー
    this.fileInputTarget.addEventListener("change", this.previewUpload.bind(this));
    
    // ネイティブカメラ撮影時プレビュー
    this.nativeCameraInputTarget.addEventListener("change", this.previewNativeCamera.bind(this));

    // 簡易スマホ判定
    const isMobile =
      /Mobi|Android|iPhone|iPad|iPod/.test(navigator.userAgent);

    if (!isMobile) {
      // PCではネイティブカメラボタンを隠す（PCにはカメラアプリがないため）
      this.nativeCameraButtonTarget.classList.add("hidden");
    }

    console.log("Native camera controller connected");
    console.log("Preview container exists:", this.hasPreviewContainerTarget);
    
    // 既存の画像がある場合の処理
    this._initializeExistingImage();
  }

  _initializeExistingImage() {
    // プレビューコンテナ内の既存画像を確認
    const existingImage = this.previewContainerTarget.querySelector('img[data-camera-target="placeholder"]');
    
    if (existingImage && existingImage.src && !existingImage.src.includes('avatar_placeholder.png')) {
      // 既存の画像がある場合、それを管理対象にする
      console.log("Existing image found:", existingImage.src);
      
      // 既存画像にcamera-targetを追加（まだない場合）
      if (!existingImage.hasAttribute('data-camera-target')) {
        existingImage.setAttribute('data-camera-target', 'placeholder');
      }
    }
  }

  openNativeCamera() {
    // ネイティブカメラアプリを起動
    this.nativeCameraInputTarget.click();
  }

  previewNativeCamera(event) {
    const file = event.target.files[0];
    if (!file) return;

    // ファイルサイズチェック（5MB制限）
    if (file.size > 5 * 1024 * 1024) {
      this._showError("ファイルサイズが大きすぎます。5MB以下のファイルを選択してください。");
      return;
    }

    // 画像ファイルかチェック
    if (!file.type.startsWith('image/')) {
      this._showError("画像ファイルを選択してください。");
      return;
    }

    // プレビュー表示
    this._displayImage(file);
    
    // 成功メッセージ
    this._showSuccess("写真を撮影しました");
  }

  previewUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    // ファイルサイズチェック（5MB制限）
    if (file.size > 5 * 1024 * 1024) {
      this._showError("ファイルサイズが大きすぎます。5MB以下のファイルを選択してください。");
      return;
    }

    // 画像ファイルかチェック
    if (!file.type.startsWith('image/')) {
      this._showError("画像ファイルを選択してください。");
      return;
    }

    // プレビュー表示
    this._displayImage(file);
    
    this._showSuccess("画像を選択しました");
  }

  _displayImage(file) {
    const url = URL.createObjectURL(file);
    
    // プレビューエリアをクリア
    this.previewContainerTarget.innerHTML = "";
    
    // 画像を表示
    const img = document.createElement('img');
    img.src = url;
    img.className = 'w-full h-full object-cover rounded';
    img.setAttribute('data-camera-target', 'placeholder');
    this.previewContainerTarget.appendChild(img);
    
    // ファイルフィールドにセット（ネイティブカメラとファイル選択の両方に対応）
    const dt = new DataTransfer();
    dt.items.add(file);
    
    // 両方のファイルフィールドにセット
    this.nativeCameraInputTarget.files = dt.files;
    this.fileInputTarget.files = dt.files;
  }

  _showError(message) {
    // エラーメッセージを表示
    console.error(message);
    alert(message); // 一時的にalertで表示
  }

  _showSuccess(message) {
    // 成功メッセージを表示
    console.log(message);
    // 必要に応じてトースト通知などを実装
  }

  disconnect() {
    // クリーンアップ処理
    console.log("Native camera controller disconnected");
  }
}
