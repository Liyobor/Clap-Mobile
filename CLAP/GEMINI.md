# CLAP to JIT (PTL) Conversion Project

## 專案目標
將 CLAP (Contrastive Language-Audio Pretraining) 的 Caption 生成模型轉換為 PyTorch JIT (TorchScript) 格式，並導出為 `.ptl` (PyTorch Lite) 檔案，以便在邊緣裝置（如行動裝置、嵌入式系統）上執行。

## 模型架構分析 (msclap 'clapcap' 版本)
1.  **Audio Encoder (音訊編碼器)**: 
    - 使用 `Cnn14` 或 `HTSAT`。
    - 內部包含 `torchlibrosa` 的 `Spectrogram` 與 `LogmelFilterBank`，將原始音訊轉換為 Log-Mel Spectrogram。
    - 輸出音訊嵌入向量 (Audio Embedding)。
2.  **Mapping Layer (映射層)**:
    - 使用 `MLP` 或 `TransformerMapper`。
    - 將音訊嵌入向量轉換為 GPT-2 能夠理解的 Prefix Embedding。
3.  **Decoder (解碼器)**:
    - 使用 `GPT2LMHeadModel` (來自 `transformers` 庫)。
    - 根據 Prefix Embedding 生成文字 Token。
4.  **Generation Logic (生成邏輯)**:
    - 目前位於 `CLAPWrapper` 的 `_generate_beam` 方法中。
    - 包含 Beam Search 迴圈。

## JIT 轉換挑戰與策略
1.  **Beam Search 腳本化**:
    - 原生的 Python 迴圈與複雜邏輯需要改寫為 `torch.jit.script` 相容的格式。
    - 對於邊緣裝置，如果效能受限，可先考慮實現 Greedy Search。
2.  **Transformers 模型相容性**:
    - `GPT2LMHeadModel` 需要被 Trace 或 Script。由於 GPT-2 有 KV Cache 等優化，Trace 較為容易但缺乏靈活性；Script 則需要處理 `transformers` 庫中的動態語法。
    - 建議：將 GPT-2 封裝在自定義 Module 中，並簡化其輸入輸出。
3.  **Tokenizer (分詞器)**:
    - Tokenizer 難以 JIT 化。
    - 策略：JIT 模型僅負責 `Audio -> Token IDs`。邊緣裝置端需配合對應的 Tokenizer (如 C++ 版本的 BPE 解碼器)。
4.  **音訊預處理**:
    - `torchaudio.load` 與 `resample` 等操作通常在模型外部。
    - 策略：JIT 模型的輸入應為固定長度的原始音訊 Tensor (Raw Waveform) 或已經提取好的 Log-Mel Spectrogram。

## 實施計畫
1.  **環境準備**: 確保 `torch` 與 `torchaudio` 版本相容，安裝 `msclap` 依賴。
    - **推薦版本 (已驗證)**:
        - `torch==2.1.0`
        - `torchaudio==2.1.0`
        - `librosa==0.10.1`
        - `numpy==1.23.0`
        - `torchlibrosa==0.1.0`
        - `transformers==4.34.0`
2.  **建立封裝模組 (`ClapcapForJit`)**:
    - 繼承 `nn.Module`。
    - 整合 `audio_encoder`, `clap_project`, `gpt_decoder`。
    - 實現內置的 `generate` 方法（Greedy Search 或 Beam Search）。
3.  **模型追蹤與腳本化 (Tracing & Scripting)**:
    - 使用 `torch.jit.trace` 處理靜態計算圖的部分。
    - 使用 `torch.jit.script` 處理包含迴圈的生成邏輯。
4.  **驗證**: 比對 JIT 模型與原模型在相同音訊輸入下的輸出結果（Token IDs）。
5.  **導出與優化**:
    - 執行 `torch.utils.mobile_optimizer.optimize_for_mobile`。
    - 儲存為 `.ptl` 格式。

## 待辦事項
- [ ] 實作 `ClapcapForJit` 類別。
- [ ] 遷移 `CLAPWrapper` 中的生成邏輯至 `ClapcapForJit`。
- [ ] 處理 GPT-2 的 `transformers` 相容性問題。
- [ ] 撰寫導出腳本 `export_jit.py`。
- [ ] 在邊緣裝置環境驗證模型加載。
