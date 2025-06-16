// app/javascript/controllers/camera_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "previewContainer",
    "placeholder",
    "shootButton",
    "captureButton",
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
      this.captureButtonTarget.classList.add("hidden");
    }

    // デバッグ用：ターゲットの存在確認
    console.log("Camera controller connected");
    console.log("Preview container exists:", this.hasPreviewContainerTarget);
    
    // canvas要素を動的に作成
    this._createCanvas();
  }

  _createCanvas() {
    // 既存のcanvasがあれば削除
    const existingCanvas = this.previewContainerTarget.querySelector('canvas');
    if (existingCanvas) {
      existingCanvas.remove();
    }

    // 新しいcanvas要素を作成
    this.canvas = document.createElement('canvas');
    this.canvas.width = 400;
    this.canvas.height = 600;
    this.canvas.classList.add('hidden', 'w-full', 'h-full', 'object-cover', 'rounded');
    
    // プレビューコンテナに追加
    this.previewContainerTarget.appendChild(this.canvas);
    
    console.log("Canvas created:", this.canvas);
  }

  startCamera() {
    this._startCamera();
  }

  capture() {
    this._capture();
  }

  async _startCamera() {
    try {
      // 利用可能なカメラデバイスを取得
      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoDevices = devices.filter(device => device.kind === 'videoinput');
      
      // 背面カメラを優先的に選択
      let preferredCamera = null;
      
      // 背面カメラを探す（環境、rear、backなどのキーワードで判定）
      preferredCamera = videoDevices.find(device => 
        device.label.toLowerCase().includes('rear') ||
        device.label.toLowerCase().includes('back') ||
        device.label.toLowerCase().includes('環境') ||
        device.label.toLowerCase().includes('背面')
      );
      
      // 背面カメラが見つからない場合は最初のカメラを使用
      if (!preferredCamera && videoDevices.length > 0) {
        preferredCamera = videoDevices[0];
      }

      // カメラの制約を設定
      const constraints = {
        video: {
          facingMode: preferredCamera ? undefined : { ideal: 'environment' }, // 背面カメラを優先
          deviceId: preferredCamera ? { exact: preferredCamera.deviceId } : undefined,
          width: { ideal: 1280 },
          height: { ideal: 720 },
          aspectRatio: { ideal: 0.75 } // 3:4のアスペクト比（縦長）
        }
      };

      const stream = await navigator.mediaDevices.getUserMedia(constraints);
      
      this.video = document.createElement("video");
      this.video.srcObject = stream;
      this.video.autoplay = true;
      this.video.playsInline = true; // iOS Safari対応
      this.video.muted = true; // 音声を無効化
      
      // ビデオの読み込み完了を待つ
      await new Promise((resolve) => {
        this.video.onloadedmetadata = () => {
          this.video.play();
          resolve();
        };
      });

      // プレビューエリアをクリアしてビデオを追加
      this.previewContainerTarget.innerHTML = "";
      this.previewContainerTarget.appendChild(this.video);
      
      // canvasを再作成
      this._createCanvas();
      
      // ビデオのサイズをプレビューエリアに合わせる
      this._adjustVideoSize();
      
      // ボタンの表示を切り替え
      this.shootButtonTarget.classList.add("hidden");
      this.captureButtonTarget.classList.remove("hidden");
      
    } catch (err) {
      console.error("カメラ起動に失敗:", err);
      
      // ユーザーにエラーを通知
      this._showError("カメラの起動に失敗しました。カメラの許可を確認してください。");
    }
  }

  _adjustVideoSize() {
    if (!this.video) return;
    
    const container = this.previewContainerTarget;
    const containerWidth = container.clientWidth;
    const containerHeight = container.clientHeight;
    
    // ビデオのアスペクト比を維持しながらコンテナに収める
    const videoAspectRatio = this.video.videoWidth / this.video.videoHeight;
    const containerAspectRatio = containerWidth / containerHeight;
    
    if (videoAspectRatio > containerAspectRatio) {
      // ビデオが横長の場合
      this.video.style.width = '100%';
      this.video.style.height = 'auto';
    } else {
      // ビデオが縦長の場合
      this.video.style.width = 'auto';
      this.video.style.height = '100%';
    }
    
    this.video.style.objectFit = 'cover';
  }

  _capture() {
    try {
      if (!this.video || !this.video.srcObject) {
        this._showError("カメラが起動していません。");
        return;
      }

      // canvasの存在確認
      if (!this.canvas) {
        console.error("Canvas not found");
        this._showError("キャプチャ機能の初期化に失敗しました。ページを再読み込みしてください。");
        return;
      }

      const ctx = this.canvas.getContext("2d");

      // キャンバスのサイズをビデオの実際のサイズに合わせる
      this.canvas.width = this.video.videoWidth;
      this.canvas.height = this.video.videoHeight;

      // ビデオをキャンバスに描画
      ctx.drawImage(this.video, 0, 0, this.canvas.width, this.canvas.height);

      // ビデオストリームを停止
      const tracks = this.video.srcObject.getTracks();
      tracks.forEach(track => track.stop());

      // プレビュー表示を切り替え
      this.canvas.classList.remove("hidden");
      this.video.remove();

      // ボタンの表示を切り替え
      this.captureButtonTarget.classList.add("hidden");
      this.shootButtonTarget.classList.remove("hidden");
      this.shootButtonTarget.textContent = "再撮影";

      // キャプチャした画像をファイルフィールドにセット
      this.canvas.toBlob(blob => {
        if (blob) {
          const file = new File([blob], `photo_${new Date().toISOString().slice(0, 19).replace(/:/g, '-')}.jpg`, { 
            type: "image/jpeg" 
          });
          const dt = new DataTransfer();
          dt.items.add(file);
          this.fileInputTarget.files = dt.files;
          
          // 成功メッセージ
          this._showSuccess("写真をキャプチャしました");
        } else {
          this._showError("画像の保存に失敗しました。");
        }
      }, "image/jpeg", 0.9);

    } catch (err) {
      console.error("画像キャプチャに失敗:", err);
      this._showError("画像のキャプチャに失敗しました。");
    }
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

    const url = URL.createObjectURL(file);
    this.previewContainerTarget.innerHTML = `
      <img src="${url}" class="w-full h-full object-cover rounded" />
    `;
    
    // 既存のビデオをクリア
    this.video?.remove();
    
    // canvasを再作成
    this._createCanvas();
    
    // ボタンの表示をリセット
    this.captureButtonTarget.classList.add("hidden");
    this.shootButtonTarget.classList.remove("hidden");
    this.shootButtonTarget.textContent = "📷 再撮影";
    
    this._showSuccess("画像を選択しました");
  }

  _showError(message) {
    // エラーメッセージを表示（簡易版）
    console.error(message);
    // 必要に応じてトースト通知などを実装
    alert(message); // 一時的にalertで表示
  }

  _showSuccess(message) {
    // 成功メッセージを表示（簡易版）
    console.log(message);
    // 必要に応じてトースト通知などを実装
  }

  disconnect() {
    // コンポーネントが破棄される際にカメラストリームを停止
    if (this.video && this.video.srcObject) {
      const tracks = this.video.srcObject.getTracks();
      tracks.forEach(track => track.stop());
    }
  }
}
