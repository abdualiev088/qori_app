"""Speech recognition for Quran recitation (Whisper tuned by Tarteel).

The model is built by hand from its weights: transformers' threaded loader
crashes on Windows with this Python. Runs on the GPU when there is one.
"""
import os
import re

import numpy as np

MODEL = 'tarteel-ai/whisper-base-ar-quran'
RATE = 16000
WINDOW = 25 * RATE  # Whisper hears at most 30 s at a time

_DIACRITICS = re.compile(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]')
_model = None


def norm(text: str) -> str:
    """Arabic letters only, without vowel marks and with unified letter forms."""
    t = _DIACRITICS.sub('', text)
    t = re.sub('[إأآٱ]', 'ا', t)
    t = t.replace('ى', 'ي').replace('ة', 'ه').replace('ؤ', 'و').replace('ئ', 'ي')
    return re.sub(r'[^ء-ي]', '', t)


def _load():
    global _model
    if _model is None:
        os.environ.setdefault('HF_HUB_OFFLINE', '1' if _cached() else '0')
        import torch
        from huggingface_hub import snapshot_download
        from transformers import WhisperConfig, WhisperForConditionalGeneration, WhisperProcessor
        from transformers.utils import logging
        logging.set_verbosity_error()
        d = snapshot_download(MODEL)
        model = WhisperForConditionalGeneration(WhisperConfig.from_pretrained(d))
        state = torch.load(os.path.join(d, 'pytorch_model.bin'), map_location='cpu', weights_only=True)
        model.load_state_dict(state, strict=False)
        model.tie_weights()
        gpu = torch.cuda.is_available()
        model = model.to('cuda' if gpu else 'cpu', torch.float16 if gpu else torch.float32).eval()
        print(f'  speech recognition on {"GPU" if gpu else "CPU"}', flush=True)
        _model = (model, WhisperProcessor.from_pretrained(d), torch)
    return _model


def _cached() -> bool:
    home = os.path.expanduser('~/.cache/huggingface/hub/models--' + MODEL.replace('/', '--'))
    return os.path.isdir(home)


def transcribe(clips: list[np.ndarray], batch: int = 0) -> list[str]:
    """Normalized text of each clip (16 kHz float). Clips longer than 25 s are
    heard in 25 s windows and their texts joined."""
    model, proc, torch = _load()
    batch = batch or int(os.environ.get('ASR_BATCH', 16))
    windows, owner = [], []
    for n, clip in enumerate(clips):
        for i in range(0, max(len(clip), 1), WINDOW):
            windows.append(clip[i:i + WINDOW])
            owner.append(n)
    order = sorted(range(len(windows)), key=lambda w: len(windows[w]))
    texts = [''] * len(windows)
    for b in range(0, len(order), batch):
        idx = order[b:b + batch]
        feats = proc.feature_extractor([windows[w] for w in idx], sampling_rate=RATE,
                                       return_tensors='pt').input_features
        for w, t in zip(idx, _generate(model, proc, torch, feats)):
            texts[w] = norm(t)
    out = [''] * len(clips)
    for w, n in enumerate(owner):
        out[n] += texts[w]
    return out


def _generate(model, proc, torch, feats):
    """Decodes a batch; on running out of GPU memory, halves it and retries."""
    try:
        with torch.no_grad():
            ids = model.generate(feats.to(model.device, model.dtype), max_new_tokens=200)
        return proc.batch_decode(ids, skip_special_tokens=True)
    except torch.AcceleratorError:
        if len(feats) == 1:
            raise
        torch.cuda.empty_cache()
        half = len(feats) // 2
        return _generate(model, proc, torch, feats[:half]) + _generate(model, proc, torch, feats[half:])


def read_audio(path, ffmpeg: str) -> np.ndarray:
    import subprocess
    raw = subprocess.run([ffmpeg, '-v', 'error', '-i', str(path), '-ac', '1', '-ar', str(RATE),
                          '-f', 'f32le', '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32)
