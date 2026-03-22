# CLAP-Mobile: Audio Captioning for Edge Devices

本專案旨在將 **CLAP (Contrastive Language-Audio Pretraining)** 模型中的音訊敘事 (Audio Captioning) 功能優化並移植至行動裝置（Android/iOS）及邊緣設備。透過 PyTorch JIT、量化技術與 Beam Search 邏輯的整合，我們產出了一個高效且精確的 `.ptl` 模型。

## 專案目標
- 將原始 1.1GB 的 Python CLAP 模型轉換為行動端優化的 **PyTorch Lite (.ptl)** 格式。
- 實現 JIT 相容的 **Beam Search** 邏輯，提升行動端生成的語義品質。
- 透過 **16-bit 級別優化與動態量化**，在維持精度的前提下提升運算效能。

## 核心組件
- **Audio Encoder**: HTSAT (Hierarchical Token Semantic Audio Transformer)，負責提取音訊特徵。
- **Mapper**: Transformer-based 映射層，將音訊特徵對齊至文字空間。
- **Decoder**: GPT-2，負責根據映射特徵生成人類可讀的描述文字。

---

## 程式碼功能說明

### 1. `export_jit.py` (核心轉換腳本)
這是本專案最重要的腳本。它執行以下操作：
- **模型提取**：從 `msclap` 套件中分離出音訊編碼器、映射層與 GPT-2 組件。
- **Beam Search JIT 化**：在 `ClapcapForJit` 類別中手動實作了支援 TorchScript 的 Beam Search 邏輯（包含 Top-K 束搜尋與 EOS 停止機制）。
- **精度優化**：對 GPT-2 執行 **Dynamic int8 Quantization**，並保持 Mapper 與音訊編碼器為 `float32` 以確保對齊精度。
- **導出 PTL**：執行 `optimize_for_mobile` 並將模型儲存為 `clap_caption_mobile.ptl`。

### 2. `compare_models.py` (品質比對工具)
用於驗證優化後的模型與原始模型的輸出差異：
- 同時載入 **原始 Python 模型** 與 **優化後的 .ptl 模型**。
- 使用 `test_audio/` 中的音檔進行推論。
- 產生對比表格，讓開發者直觀地確認語義是否因量化或 Beam Search 實作而產生偏差。

### 3. `export_tokenizer.py` (分詞器導出工具)
行動端 App 無法直接執行 Python 的 `transformers` 庫，因此需要此腳本：
- 導出 GPT-2 的詞彙表檔案：`vocab.json` 與 `merges.txt`。
- 導出 `tokenizer.json`，這是在行動端（如 Swift 或 Kotlin）使用 Hugging Face Tokenizer 庫時所需的標準格式。

### 4. `test_mobile_model.py` (移動端模擬測試)
專門測試 `.ptl` 檔案的獨立腳本：
- 模擬 App 環境，使用 `torch.jit` 加載模型。
- 包含完整的音訊預處理邏輯（重採樣、單聲道轉換、固定時長填充）。
- 驗證模型是否能正確輸出 Token IDs 並成功解碼。

### 5. `main.py` (原始入口)
用於測試原始 `msclap` 套件的基本功能，確保環境配置正確及測試音檔可用。

---

## 優化技術細節
- **JIT Tracing**: 解決了 Python 靈活動態特性與行動端靜態執行環境的衝突。
- **Dynamic Quantization**: 針對 GPT-2 的線性層進行量化，大幅減少了內存帶寬需求。
- **Beam Search Implementation**: 相比於簡單的 Greedy Search，Beam Search 雖然增加了實作難度，但顯著提升了生成的穩定性，避免了重複詞彙與語義斷裂。

## 如何開始
1. 確保已安裝環境推薦版本（詳見 `GEMINI.md`）。
2. 運行 `python export_jit.py` 產生行動端模型。
3. 運行 `python compare_models.py` 驗證模型品質。
4. 運行 `python export_tokenizer.py` 取得行動端所需的詞彙表。

## 產出檔案
- `clap_caption_mobile.ptl`: 最終行動端模型檔案。
- `tokenizer_files/`: 內含 `tokenizer.json`, `vocab.json`, `merges.txt`。
