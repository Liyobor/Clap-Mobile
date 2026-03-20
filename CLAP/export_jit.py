import torch
import torch.nn as nn
from torch.utils.mobile_optimizer import optimize_for_mobile
from msclap import CLAP
import os
import torchaudio
import torchaudio.transforms as T

# ---------------------------------------------------------
# 1. Define JIT-friendly wrapper with Beam Search
# ---------------------------------------------------------
class ClapcapForJit(nn.Module):
    def __init__(self, audio_encoder, mapper, gpt, eos_token_id, prefix_length, gpt_embedding_size, normalize_prefix):
        super().__init__()
        self.audio_encoder = audio_encoder
        self.clap_project = mapper
        self.gpt = gpt
        
        self.eos_token_id = eos_token_id
        self.prefix_length = prefix_length
        self.gpt_embedding_size = gpt_embedding_size
        self.normalize_prefix = normalize_prefix

    def forward(self, audio_waveform: torch.Tensor, max_length: int = 20, beam_size: int = 5):
        # 1. Audio Encoding (FP32)
        prefix, _ = self.audio_encoder(audio_waveform)
        if self.normalize_prefix:
            prefix = prefix / prefix.norm(2, -1).reshape(-1, 1)
            
        # 2. Project to GPT space
        prefix_projections = self.clap_project(prefix).view(-1, self.prefix_length, self.gpt_embedding_size)
        
        # 3. Beam Search Initialization
        device = audio_waveform.device
        generated = prefix_projections.expand(beam_size, -1, -1) 
        
        scores = torch.zeros(beam_size, device=device)
        tokens = torch.zeros((beam_size, max_length), dtype=torch.long, device=device)
        is_stopped = torch.zeros(beam_size, device=device, dtype=torch.bool)

        # First step
        outputs = self.gpt(inputs_embeds=generated[:1], return_dict=False)
        logits = outputs[0][0, -1, :] # [vocab_size]
        logits = torch.log_softmax(logits, dim=-1)
        
        top_scores, top_indices = torch.topk(logits, beam_size)
        scores = top_scores
        tokens[:, 0] = top_indices
        
        # Update generated
        next_token_embeds = self.gpt.transformer.wte(top_indices.unsqueeze(-1)) 
        generated = torch.cat([generated, next_token_embeds], dim=1)

        # Loop for Beam Search
        for i in range(1, max_length):
            if is_stopped.all():
                break
                
            outputs = self.gpt(inputs_embeds=generated, return_dict=False)
            logits = outputs[0][:, -1, :] 
            logits = torch.log_softmax(logits, dim=-1)
            
            combined_scores = scores.unsqueeze(1) + logits
            flat_scores = combined_scores.view(-1)
            top_scores, top_indices = torch.topk(flat_scores, beam_size)
            
            beam_indices = top_indices // logits.shape[1]
            token_indices = top_indices % logits.shape[1]
            
            scores = top_scores
            tokens = tokens[beam_indices]
            tokens[:, i] = token_indices
            generated = generated[beam_indices]
            is_stopped = is_stopped[beam_indices]
            
            # Check for EOS
            new_stopped = (token_indices == self.eos_token_id)
            is_stopped = is_stopped | new_stopped
            
            next_token_embeds = self.gpt.transformer.wte(token_indices.unsqueeze(-1))
            generated = torch.cat([generated, next_token_embeds], dim=1)

        best_beam_idx = torch.argmax(scores)
        return tokens[best_beam_idx].unsqueeze(0)

def main():
    print("Loading original msclap components...")
    clap_wrapper = CLAP(version='clapcap', use_cuda=False)
    clapcap = clap_wrapper.clapcap
    args = clap_wrapper.args
    tokenizer = clap_wrapper.tokenizer
    eos_token_id = tokenizer.eos_token_id if tokenizer.eos_token_id is not None else 50256

    # Assemble JIT Wrapper in float32 first (for CPU tracing)
    print("Assembling JIT model (float32)...")
    model_jit = ClapcapForJit(
        clapcap.clap,
        clapcap.clap_project,
        clapcap.gpt,
        eos_token_id,
        args.prefix_length,
        clapcap.gpt_embedding_size,
        args.normalize_prefix
    ).eval()

    # Trace in float32
    print("Tracing in float32...")
    dummy_input = torch.randn(1, 7 * 44100)
    traced_model = torch.jit.trace(model_jit, (dummy_input,), check_trace=False)
    
    # Now we perform 16-bit optimization for Mobile
    # For Mobile CPU, int8 dynamic quantization is usually better than float16.
    # But if you want float16, it is typically done via the mobile optimizer 
    # or by converting weights after tracing.
    
    print("Applying Mobile Optimizations...")
    # This optimization pass can include many things. 
    # To truly get float16, we might need to convert the model.
    # However, mobile CPU doesn't support float16 well. 
    # Let's try to convert the traced model to float16 if supported.
    try:
        # Note: most mobile interpreters support float16 weights via quantization
        mobile_model = optimize_for_mobile(traced_model)
    except Exception as e:
        print(f"Mobile optimization error: {e}")
        mobile_model = traced_model

    # Final Save
    output_path = "clap_caption_mobile.ptl"
    mobile_model._save_for_lite_interpreter(output_path)
    
    print(f"\nSUCCESS: Exported to {output_path}")
    print(f"Final Size: {os.path.getsize(output_path) / (1024*1024):.2f} MB")

    # Local Verification
    print("\nLocal verification (Laugh audio):")
    audio, _ = torchaudio.load("./test_audio/laugh.wav")
    if audio.shape[1] > 7*44100: audio = audio[:, :7*44100]
    else: audio = torch.nn.functional.pad(audio, (0, 7*44100 - audio.shape[1]))
    
    with torch.no_grad():
        output = traced_model(audio.reshape(1, -1))
        tokens = output[0].tolist()
        if eos_token_id in tokens: tokens = tokens[:tokens.index(eos_token_id)]
        print(f"Generated: {tokenizer.decode(tokens).strip().capitalize()}")

if __name__ == "__main__":
    main()
