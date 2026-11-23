"""Cut a full-surah recitation into one MP3 per ayah.

    python split_surah.py alijon 1          # one surah
    python split_surah.py alijon 1-114      # a range

How it works:
1. Downloads the surah's MP3 from the reciter's server (cached in cache/<reciter>/).
2. Finds the pauses: 20 ms frames whose loudness is far below the recording's median.
3. Recognizes the words of every stretch of speech between pauses (Whisper
   tuned on Quran recitation, see asr.py).
4. Dynamic programming groups consecutive stretches into units, in order: the
   basmala (optional; not in surahs 1 and 9), then each ayah, so that the
   recognized text best matches each unit's text. Stretches that match nothing
   (isti'adha, a repeated phrase) are left out and listed in the report.
5. Copies each unit out without re-encoding (no quality loss), with a little
   silence kept on both sides, into out/<folder>/<NN. Surah>/<NN. First words>.mp3.
   The basmala is the same before every surah, so only one is kept per
   reciter: out/<folder>/00. Bismillah.mp3 (in Al-Fatihah it is ayah 1).

Every run writes report.json next to the surah's files: timings, what was
heard and how similar it is to the ayah's text (sim, 0..1).
"""

from __future__ import annotations

import json
import math
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

import imageio_ffmpeg
import numpy as np
from rapidfuzz.distance import Indel

import asr

ROOT = Path(__file__).parent
CACHE = ROOT / 'cache'
OUT = ROOT / 'out'
SURAHS_DART = ROOT.parent.parent / 'lib' / 'data' / 'surahs.dart'

RECITERS = {
    'alijon': {
        'folder': 'Alijon qori qiroati',
        'url': 'https://cdn.mp3quran.net/audio/alijon-hamdan/r1/{surah:03d}.mp3',
    },
}

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
RATE = 16000
HOP = 0.02  # seconds per analysis frame
MIN_PAUSE = 0.25  # shorter quiet stretches are breaths inside words, not pauses
PAD_BEFORE = 0.15
PAD_AFTER = 0.35
# Inside the recording an ayah ends at the quietest point of the pause after it,
# but never further than this from its last sound (long pauses stay short).
PAD_BEFORE_MAX = 0.6
PAD_AFTER_MAX = 1.2
MIN_HEARD = 0.3  # seconds
PAUSE_BONUS = 2.0  # letters of text match per e-fold of pause length at an ayah's end
BASMALA = 'بسم الله الرحمن الرحيم'


# ---------- text ----------

def _load(name: str) -> list[list[str]]:
    data = json.loads((CACHE / 'text' / name).read_text(encoding='utf-8-sig'))
    return [[a['text'].lstrip('﻿') for a in s['ayahs']] for s in data['data']['surahs']]


def ayah_texts(surah: int) -> list[str]:
    ayahs = _load('simple-clean.json')[surah - 1]
    if surah not in (1, 9) and ayahs[0].startswith(BASMALA):
        ayahs = [ayahs[0][len(BASMALA):].strip(), *ayahs[1:]]
    return ayahs


def ayah_names(surah: int) -> list[str]:
    """The first one or two words of each ayah, transliterated: 'Alhamdu lillaahi'."""
    names = []
    for text in _load('transliteration.json')[surah - 1]:
        words = re.sub(r'<[^>]+>', '', text).split()
        name = ' '.join(words[:2])
        if len(name) > 28:
            name = words[0]
        names.append(re.sub(r'[\\/:*?"<>|]', '', name).strip())
    return names


def surah_names() -> list[str]:
    """Surah names from the app (lib/data/surahs.dart), so both use the same spelling."""
    src = SURAHS_DART.read_text(encoding='utf-8')
    block = src[src.index('surahNames') : src.index('];')]
    return [m.group(1) or m.group(2) for m in re.finditer(r'"([^"]+)"|\'([^\']+)\'', block)][:114]


# The disjoined letters (Alif-Lam-Mim...) are read by their names, long-drawn:
# "الم" is three letters on the page but about eight seconds aloud.
_LETTER_NAMES = {'ا': 'الف', 'ل': 'لام', 'م': 'ميم', 'ص': 'صاد', 'ر': 'راء', 'ك': 'كاف', 'ه': 'هاء',
                 'ي': 'ياء', 'ع': 'عين', 'ط': 'طاء', 'س': 'سين', 'ح': 'حاء', 'ق': 'قاف', 'ن': 'نون'}
_MUQATTAAT = {'الم', 'المص', 'الر', 'المر', 'كهيعص', 'طه', 'طسم', 'طس', 'يس', 'ص', 'حم', 'عسق', 'ق', 'ن'}


# ---------- audio ----------

def download(reciter: str, surah: int, parts: int = 16) -> Path:
    """Fetches the surah in [parts] byte ranges at once: the CDN gives each
    connection only about 100 KB/s, and Al-Baqarah alone is 380 MB."""
    path = CACHE / reciter / f'{surah:03d}.mp3'
    if path.exists():
        return path
    path.parent.mkdir(parents=True, exist_ok=True)
    url = RECITERS[reciter]['url'].format(surah=surah)
    with urllib.request.urlopen(urllib.request.Request(url, method='HEAD')) as r:
        size = int(r.headers['Content-Length'])
    print(f'  downloading {url} ({size / 1e6:.0f} MB)')
    step = math.ceil(size / parts)
    chunks = [(path.with_suffix(f'.part{i:02d}'), i * step, min(size, (i + 1) * step) - 1) for i in range(parts)]
    for attempt in range(5):
        todo = [c for c in chunks if not c[0].exists() or c[0].stat().st_size != c[2] - c[1] + 1]
        if not todo:
            break
        procs = [subprocess.Popen(['curl', '-s', '--retry', '3', '-r', f'{a}-{b}', '-o', str(p), url]) for p, a, b in todo]
        for proc in procs:
            proc.wait()
    else:
        raise RuntimeError(f'could not download {url}')
    with open(path.with_suffix('.tmp'), 'wb') as out:
        for p, _, _ in chunks:
            out.write(p.read_bytes())
            p.unlink()
    path.with_suffix('.tmp').rename(path)
    return path


# From strict to loose: (dB below the median that counts as quiet, shortest pause).
# Short ayahs are often read in one breath, so a surah with many of them needs
# the looser levels to find a place to cut between every pair.
PAUSE_LEVELS = [(12, 0.12), (15, 0.18), (18, 0.25), (9, 0.08)]


def loudness(x: np.ndarray) -> tuple[np.ndarray, float]:
    """Loudness in dB per 20 ms frame, and the recording's length."""
    hop = int(RATE * HOP)
    n = len(x) // hop
    return 20 * np.log10(np.sqrt((x[: n * hop].reshape(n, hop) ** 2).mean(1)) + 1e-6), len(x) / RATE


def speech_pieces(db: np.ndarray, drop: float, min_pause: float) -> list[tuple[float, float]]:
    """Stretches of speech between pauses."""
    n = len(db)
    quiet = db < np.median(db) - drop
    min_frames = round(min_pause / HOP)

    pieces, start, i = [], None, 0
    while i < n:
        if quiet[i]:
            j = i
            while j < n and quiet[j]:
                j += 1
            if j - i >= min_frames or j == n:
                if start is not None:
                    pieces.append((start * HOP, i * HOP))
                    start = None
            i = j
        else:
            if start is None:
                start = i
            i += 1
    if start is not None:
        pieces.append((start * HOP, n * HOP))
    return pieces


# ---------- alignment ----------

def _match(heard: str, ref: str) -> float:
    """Letters in common, minus half of what either side has extra: a perfect
    match scores len(ref), a piece of noise scores -len(noise)/2."""
    m = (len(heard) + len(ref) - Indel.distance(heard, ref)) / 2
    return 2 * m - 0.5 * (len(heard) + len(ref))


def align(heard: list[str], refs: list[str], optional: set[int], gaps: list[float] | None = None,
          max_span: int = 80, band: float = 0.12):
    """Groups consecutive speech pieces (their recognized text in [heard]) into
    units whose text is [refs], in order, by dynamic programming over text
    similarity. Pieces may be left out between units (isti'adha before the
    surah, a repeated phrase, "sadaqallah" at the end); units in [optional]
    may be absent (the basmala). Returns one (first, last) piece range per
    unit, or None for an absent unit.

    [gaps][i] is the pause after piece i. Ending a unit at a long pause earns a
    small bonus: a short stop inside the last word of an ayah (the k of
    "dhikr", a sukun) splits off its tail as a separate piece the recognizer
    barely hears, and without the bonus that tail could go either way."""
    if gaps is None:
        gaps = [1.0] * len(heard)
    bonus = [PAUSE_BONUS * math.log(max(g, 0.02) / 0.12) for g in gaps]
    m, k = len(heard), len(refs)
    total_h = sum(map(len, heard)) or 1
    total_r = sum(map(len, refs)) or 1
    cum_h = np.cumsum([0] + [len(h) for h in heard]) / total_h
    cum_r = np.cumsum([0] + [len(r) for r in refs]) / total_r
    band = max(band, 300 / total_r)
    neg = -math.inf
    # score[j][i]: best with the first j units placed within the first i pieces
    score = np.full((k + 1, m + 1), neg)
    back = {}
    score[0][0] = 0.0
    for j in range(k + 1):
        for i in range(m + 1):
            cur = score[j][i]
            if cur == neg:
                continue
            # leave piece i out
            if i < m:
                v = cur - 0.4 * len(heard[i])
                if v > score[j][i + 1]:
                    score[j][i + 1], back[(j, i + 1)] = v, ('skip', i)
            if j == k:
                continue
            if j in optional and cur > score[j + 1][i]:
                score[j + 1][i], back[(j + 1, i)] = cur, ('absent', i)
            if abs(cum_h[i] - cum_r[j]) > band:
                continue
            text = ''
            for e in range(i, min(m, i + max_span)):
                text += heard[e]
                if len(text) > 2.5 * len(refs[j]) + 40:
                    break
                v = cur + _match(text, refs[j]) + bonus[e]
                if v > score[j + 1][e + 1]:
                    score[j + 1][e + 1], back[(j + 1, e + 1)] = v, ('unit', i)
    if score[k][m] == neg:
        if band < 1:
            return align(heard, refs, optional, gaps, max_span, band * 2)
        raise RuntimeError('could not align the recitation to the text')
    groups, j, i = [None] * k, k, m
    while j > 0 or i > 0:
        kind, s = back[(j, i)]
        if kind == 'skip':
            i = s
        elif kind == 'absent':
            j -= 1
        else:
            groups[j - 1] = (s, i - 1)
            j, i = j - 1, s
    return groups


def similarity(heard: str, ref: str) -> float:
    return round(Indel.normalized_similarity(heard, ref), 2)


# ---------- cutting ----------

def cut(src: Path, dst: Path, start: float, end: float):
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [FFMPEG, '-v', 'error', '-y', '-ss', f'{start:.3f}', '-to', f'{end:.3f}', '-i', str(src),
         '-c', 'copy', '-map_metadata', '-1', str(dst)],
        check=True,
    )


def spoken_text(surah: int, ayah: int, text: str) -> str:
    """The ayah as the recognizer writes it (disjoined letters stay as written: طسم)."""
    return asr.norm(text)


def quietest(db: np.ndarray, a: float, b: float) -> float:
    """The quietest moment of the pause between a and b (smoothed over 60 ms).

    Cutting there rather than at the pause's middle keeps a long-drawn ending
    (the madd of "dihaqa") whole: it fades through most of the pause, and the
    quietest point is usually the breath just before the next ayah."""
    i, j = int(a / HOP), max(int(a / HOP) + 1, int(b / HOP))
    seg = db[i:j]
    if len(seg) < 3:
        return (a + b) / 2
    smooth = np.convolve(seg, np.ones(3) / 3, mode='same')
    k = int(np.argmin(smooth[1:-1])) + 1
    return (i + k + 0.5) * HOP


def _absorb(groups, pieces, heard, refs):
    """Extends each ayah over the left-out pieces between it and the next one.
    Each such piece goes to the neighbour whose text it sounds more like (a
    reciter often repeats the end of the ayah he just read); ties are cut at
    the longest pause."""
    groups = list(groups)
    idx = [n for n, g in enumerate(groups) if g]
    for p, q in zip(idx, idx[1:]):
        (a, b), (c, d) = groups[p], groups[q]
        if c - b <= 1:
            continue

        def score(cut):
            left = sum(_match(heard[i], refs[p]) for i in range(b + 1, cut + 1))
            right = sum(_match(heard[i], refs[q]) for i in range(cut + 1, c))
            pause = pieces[cut + 1][0] - pieces[cut][1]
            return (round(left + right, 1), pause)

        cut = max(range(b, c), key=score)
        groups[p], groups[q] = (a, cut), (cut + 1, d)
    return groups


def _heard(reciter, surah, level, audio, pieces):
    """Recognized text of each piece, cached on disk: the laptop GPU sometimes
    fails mid-surah, and a retry should not start from scratch."""
    path = CACHE / 'asr' / reciter / f'{surah:03d}_{level[0]}_{level[1]}.json'
    heard = json.loads(path.read_text(encoding='utf-8')) if path.exists() else []
    path.parent.mkdir(parents=True, exist_ok=True)
    while len(heard) < len(pieces):
        part = pieces[len(heard):len(heard) + 160]
        heard += asr.transcribe([audio[int(a * RATE):int(b * RATE)] for a, b in part])
        path.write_text(json.dumps(heard, ensure_ascii=False), encoding='utf-8')
    return heard


def split(reciter: str, surah: int):
    cfg = RECITERS[reciter]
    name = surah_names()[surah - 1]
    print(f'{surah:03d} {name}', flush=True)
    mp3 = download(reciter, surah)
    audio = asr.read_audio(mp3, FFMPEG)
    db, length = loudness(audio)

    texts, titles = ayah_texts(surah), ayah_names(surah)
    labels = [(n + 1, f'{n + 1:02d}. {t}') for n, t in enumerate(titles)]
    refs = [spoken_text(surah, n + 1, t) for n, t in enumerate(texts)]
    optional = set()
    if surah not in (1, 9):
        labels.insert(0, (0, '00. Bismillah'))
        refs.insert(0, asr.norm(BASMALA))
        optional.add(0)

    # Medium pause detection works best; if some ayah still matches poorly
    # (two ayahs in one breath, or a word cut by a breath), try the others.
    best = None
    for drop, min_pause in PAUSE_LEVELS:
        p = speech_pieces(db, drop, min_pause)
        h = _heard(reciter, surah, (drop, min_pause), audio, p)
        # On a breath or a click shorter than this the recognizer makes words up.
        h = [t if b - a >= MIN_HEARD else '' for t, (a, b) in zip(h, p)]
        try:
            gaps = [b[0] - a[1] for a, b in zip(p, p[1:])] + [10.0]
            g = align(h, refs, optional, gaps)
        except RuntimeError:
            print(f'  pauses {drop} dB / {min_pause} s: some breath holds several ayahs, trying another level')
            continue
        sims = [similarity(''.join(h[x:y + 1]), r) for x_y, r in zip(g, refs) if x_y
                for x, y in [x_y]]
        found = sum(1 for x in g if x)
        rank = (found, min(sims), sum(sims) / len(sims))
        if best is None or rank > best[0]:
            best = (rank, p, h, g)
        if min(sims) >= 0.6 and found >= len(refs) - len(optional):
            break
    if best is None:
        raise RuntimeError('could not align the recitation to the text at any pause level')
    _, pieces, heard, groups = best

    folder = OUT / cfg['folder'] / f'{surah:02d}. {name}'
    if folder.exists():
        for old in folder.glob('*.mp3'):
            old.unlink()
    used = {i for g in groups if g for i in range(g[0], g[1] + 1)}
    report = {'surah': surah, 'name': name, 'length': round(length, 2), 'pieces': len(pieces),
              'skipped': [{'start': round(pieces[i][0], 2), 'end': round(pieces[i][1], 2), 'heard': heard[i]}
                          for i in range(len(pieces)) if i not in used],
              'ayahs': []}
    first = min(used)
    # A stretch left out between two ayahs is most likely part of one of them,
    # misheard (or a repeated phrase): give it to the nearer one rather than lose it.
    groups = _absorb(groups, pieces, heard, refs)
    for (n, label), g, ref in zip(labels, groups, refs):
        if g is None:
            continue
        a, b = g
        if a > 0:
            start = max(quietest(db, pieces[a - 1][1], pieces[a][0]), pieces[a][0] - PAD_BEFORE_MAX)
        else:
            start = max(0.0, pieces[a][0] - PAD_BEFORE)
        if b + 1 < len(pieces):
            end = min(quietest(db, pieces[b][1], pieces[b + 1][0]), pieces[b][1] + PAD_AFTER_MAX)
        else:
            end = min(length, pieces[b][1] + PAD_AFTER_MAX)
        got = ''.join(heard[a:b + 1])
        entry = {'ayah': n, 'file': f'{label}.mp3', 'start': round(start, 2), 'end': round(end, 2),
                 'pieces': b - a + 1, 'sim': similarity(got, ref), 'heard': got}
        if n == 0:
            # The basmala is the same words before every surah: keep one per reciter.
            shared = OUT / cfg['folder'] / '00. Bismillah.mp3'
            if not shared.exists():
                cut(mp3, shared, start, end)
            report['basmala'] = entry
            continue
        cut(mp3, folder / entry['file'], start, end)
        report['ayahs'].append(entry)
    if first > 0:
        cut(mp3, OUT / cfg['folder'] / '_extra' / f'{surah:03d}_istiadha.mp3',
            max(0, pieces[0][0] - PAD_BEFORE), pieces[first - 1][1] + PAD_AFTER)
    (folder / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding='utf-8')

    missing = [n for (n, _), g in zip(labels, groups) if g is None and n > 0]
    worst = sorted(report['ayahs'], key=lambda r: r['sim'])[:3]
    print(f'  {len(report["ayahs"])} files, {len(pieces)} pieces, {len(report["skipped"])} left out'
          + (f', MISSING {missing}' if missing else ''))
    print('  least similar:', ', '.join(f"{r['ayah']} ({r['sim']:.2f})" for r in worst), flush=True)


def main():
    reciter, span = sys.argv[1], sys.argv[2]
    if len(sys.argv) > 3 and sys.argv[3] == '--here':
        split(reciter, int(span))
        return
    # Each surah in its own process: after a GPU error CUDA is unusable for the
    # rest of the process. Three tries on the GPU with smaller and smaller
    # batches, then one on the CPU.
    import os
    a, _, b = span.partition('-')
    failed = []
    for surah in range(int(a), int(b or a) + 1):
        for attempt in range(4):
            env = dict(os.environ)
            env['ASR_BATCH'] = str([16, 4, 1, 16][attempt])
            if attempt == 3:
                env['CUDA_VISIBLE_DEVICES'] = '-1'
                print('  GPU keeps failing, using the CPU', flush=True)
            elif attempt:
                print(f'  retrying with batches of {env["ASR_BATCH"]}', flush=True)
            r = subprocess.run([sys.executable, __file__, reciter, str(surah), '--here'], env=env)
            if r.returncode == 0:
                break
        else:
            failed.append(surah)
    if failed:
        print('FAILED:', failed)


if __name__ == '__main__':
    main()
