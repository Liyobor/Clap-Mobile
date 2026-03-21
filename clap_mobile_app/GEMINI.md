# Clap-Mobile App Mandates

This document outlines the foundational mandates, architectural patterns, and UI/UX standards for the Clap-Mobile sound recognition application.

## Project Overview
Clap-Mobile is a Flutter application designed for environmental sound recognition. The app records short bursts of audio (7 seconds) and uses a pre-trained PyTorch Mobile model to generate descriptive captions of the acoustic environment.

## Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** GetX
- **Inference Engine:** `flutter_pytorch_lite`
- **Audio Management:** `taudio` (Recording, Playback, and Waveform Visualizer)
- **Model:** `clap_caption_mobile.ptl` (PyTorch Mobile)

## Architecture & Folder Structure
Adhere to the following structure for scalability and maintainability:
- `lib/home/`: Main screen logic and UI.
    - `view.dart`: UI components and layout.
    - `logic.dart`: State management and business logic using `GetxController`.
- `lib/services/`: Persistent services.
    - `model_holder.dart`: Manages PyTorch model loading and inference.
- `lib/utils.dart`: Common utility functions.
- `assets/model/`: PyTorch Mobile model files.
- `assets/test_audio/`: Sample audio for testing.

## UI/UX Standards (Mandatory)
Based on `UI.png`, the app must follow a modern, dark, and "high-tech" aesthetic:
- **Theme:** Strictly **Dark Mode**.
    - Primary Background: Dark navy/charcoal gradient or solid.
    - Accent Colors: Cyan/Neon Blue (glows), Red (stop button).
- **Core Components:**
    - **Audio Visualizer:** A circular, glowing waveform visualizer that reacts to microphone input (if possible) or shows a pulsing animation during recording.
    - **Action Button:** A pill-shaped button with a glow. "Stop Recording" should be red with a glowing border.
    - **Status Label:** "RECOGNIZING..." or "RECORDING..." in uppercase with a clean, sans-serif font (e.g., Inter).
    - **Result Card:**
        - Semi-transparent background (Glassmorphism effect).
        - Rounded corners (radius ~20).
        - White text for the description.
        - Bottom row with icons (sound category icons) and "Confidence: XX%".
- **Typography:** Modern sans-serif (Inter, NotoSansTC).

## Technical Mandates
1. **Model Specs:**
    - Input: `Float32List` of length `44100 * 7` (7 seconds at 44.1kHz).
    - Output: Model generates a text caption.
2. **Resource Management:**
    - Ensure `ModelHolder` is initialized only once (via `Get.put`).
    - Explicitly `destroy()` the module in `onClose`.
3. **Permission Handling:**
    - Request microphone permissions before starting any recording session.
4. **State Flow & Cancellation:**
    - **Idle** -> **Recording** (7 seconds) -> **Recognizing** (Inference) -> **Result Display**.
    - **Recording Cancellation:** Users must be able to cancel an active recording session at any time. If canceled, the audio data should be discarded, and the app should return to the **Idle** state without triggering inference.
    - Ensure `taudio` sessions are properly released if a recording is canceled.

## Testing & Validation
- Use sample audio in `assets/test_audio/` to verify inference logic.
- UI must be responsive across different screen sizes while maintaining the aesthetic integrity of `UI.png`.
