from transformers import AutoTokenizer
import json
import os

def export_tokenizer():
    print("Loading GPT-2 Tokenizer...")
    tokenizer = AutoTokenizer.from_pretrained("gpt2")
    
    # Create directory for tokenizer files
    output_dir = "tokenizer_files"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    print(f"Exporting tokenizer files to {output_dir}...")
    
    # 1. Save standard files (vocab.json and merges.txt)
    tokenizer.save_pretrained(output_dir)
    
    # 2. Specifically ensure we have the core files
    # vocab.json: Maps words/subwords to IDs
    # merges.txt: Rules for BPE merging
    
    print("\n--- Files Exported ---")
    files = os.listdir(output_dir)
    for f in files:
        size = os.path.getsize(os.path.join(output_dir, f)) / 1024
        print(f"- {f:<20} ({size:.2f} KB)")
        
    print("\nNote for Mobile Implementation:")
    print("1. Most libraries (like Hugging Face Tokenizers for Swift/Kotlin) expect 'vocab.json' and 'merges.txt'.")
    print("2. The 'tokenizer.json' is a newer all-in-one format that includes rules and special tokens.")

if __name__ == "__main__":
    export_tokenizer()
