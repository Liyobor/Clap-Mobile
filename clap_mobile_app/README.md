# Clap-Mobile Sound Recognition App

Clap-Mobile is a modern Flutter application designed for real-time environmental sound recognition. The app captures short bursts of audio and leverages a mobile-optimized version of **Microsoft CLAP (Contrastive Language-Audio Pretraining)** to generate descriptive captions of the acoustic environment.

## Main Purpose
The primary goal of this application is to provide users with an intelligent "acoustic-to-text" experience. By recording 7 seconds of ambient sound, the app uses a PyTorch Mobile model to understand the context and outputs a human-readable description (e.g., "A person is laughing" or "The sound of rain hitting a window").

## Tech Stack
- **Framework:** Flutter (Dart)
  - **State Management:** GetX
  - **Inference Engine:** `flutter_pytorch_lite` (PyTorch Mobile)
  - **Audio Management:** `taudio` (High-performance audio recording)
  - **Tokenizer:** Custom GPT-2 Byte-level BPE Decoder

## System Architecture

The app follows a clean, service-oriented architecture using GetX for dependency injection and state management.

```mermaid
graph TD
    UI[HomePage - lib/home/view.dart] <--> Logic[HomeLogic - lib/home/logic.dart]
    Logic --> Audio[taudio - Recorder]
    Logic --> Model[ModelHolder - lib/services/model_holder.dart]
    Logic --> Tokenizer[TokenizerService - lib/services/tokenizer_service.dart]
    
    subgraph Core Services
        Model --> PTL[clap_caption_mobile.ptl]
        Tokenizer --> Vocab[vocab.json]
    end
```

## Workflow Sequence

The following diagram illustrates the lifecycle of a sound recognition request, from user interaction to result display.

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant L as HomeLogic
    participant R as Recorder (taudio)
    participant M as ModelHolder (PTL)
    participant T as TokenizerService
    
    U->>L: Tap "Start Recording"
    L->>L: Request Mic Permission
    L->>R: Record 7s (PCM16, 44100Hz)
    Note over R: 7 Seconds Elapses...
    R-->>L: Return temp_audio.pcm
    L->>L: Convert PCM16 to Float32 Tensor
    L->>M: inference(Float32List)
    M->>M: Forward Pass (PyTorch)
    M-->>L: Return Token IDs (Int64List)
    L->>T: decode(tokenIds)
    T->>T: Byte-level BPE Decoding
    T-->>L: "A person is laughing"
    L->>U: Display Result on ResultCard
```

## Project Structure
- `lib/home/`: Contains the main UI and business logic.
  - `lib/services/`: Persistent services for AI model management and text decoding.
  - `assets/model/`: The PyTorch Mobile `.ptl` model file.
  - `assets/tokenizer_files/`: Vocabulary and mapping files for GPT-2 decoding.