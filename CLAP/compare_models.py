import torch
import torchaudio
import torchaudio.transforms as T
from msclap import CLAP
from transformers import AutoTokenizer
import os

def load_audio_for_jit(path, target_sr=44100, target_duration=7):
    waveform, sr = torchaudio.load(path)
    if sr != target_sr:
        waveform = T.Resample(sr, target_sr)(waveform)
    if waveform.shape[0] > 1:
        waveform = torch.mean(waveform, dim=0, keepdim=True)
    waveform = waveform.reshape(-1)
    target_samples = target_sr * target_duration
    if len(waveform) < target_samples:
        waveform = torch.nn.functional.pad(waveform, (0, target_samples - len(waveform)))
    else:
        waveform = waveform[:target_samples]
    return waveform.unsqueeze(0)

def main():
    mobile_model_path = "clap_caption_mobile.ptl"
    test_files = ["./test_audio/curse.wav", "./test_audio/laugh.wav"]
    
    if not os.path.exists(mobile_model_path):
        print(f"Error: {mobile_model_path} not found. Please run export_jit.py first.")
        return

    print("--- Model Comparison Test ---")
    
    # 1. Load Original Model
    print("Loading Original CLAP Model...")
    clap_wrapper = CLAP(version='clapcap', use_cuda=False)
    
    # 2. Load Mobile Model
    print(f"Loading Mobile Optimized Model: {mobile_model_path}...")
    mobile_model = torch.jit.load(mobile_model_path)
    mobile_model.eval()

    # Tokenizer for decoding
    tokenizer = AutoTokenizer.from_pretrained("gpt2")
    eos_token_id = tokenizer.eos_token_id if tokenizer.eos_token_id is not None else 50256

    print("\n" + "="*100)
    print(f"{'Audio File':<20} | {'Original':<35} | {'Mobile'}")
    print("-" * 100)

    for audio_path in test_files:
        # Original Inference
        orig_caption = clap_wrapper.generate_caption([audio_path])[0]
        
        # Mobile Inference
        input_tensor = load_audio_for_jit(audio_path)
        with torch.no_grad():
            output_tokens = mobile_model(input_tensor)
        
        tokens = output_tokens[0].tolist()
        if eos_token_id in tokens:
            tokens = tokens[:tokens.index(eos_token_id)]
        mobile_caption = tokenizer.decode(tokens).strip().capitalize()
        
        print(f"{os.path.basename(audio_path):<20} | {orig_caption:<35} | {mobile_caption}")

    print("="*100)

if __name__ == "__main__":
    main()
