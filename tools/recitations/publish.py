"""Prepares a reciter's cut ayahs for the app and uploads them to Cloudflare R2.

    python publish.py build alijon            # encode + file lists, into publish/
    python publish.py upload alijon           # send new files to R2 (.r2.env)

build:
- Encodes every ayah from out/ to MP3 96 kbps mono CBR. A voice sounds the
  same as at 190 kbps, and a listener spends half the data. Constant bitrate
  keeps seeking exact in the player.
- Names each file after its content: alijon/055/054-<sha256[:12]>.mp3. A
  fixed recording gets a new name, so phones and the CDN can cache every
  file forever (docs/DECISIONS.md).
- Writes publish/manifests/<reciter>/NNN.json per surah (read by
  lib/data/audio_cache.dart): each ayah's url,
  size, sha256 and duration_ms, plus the shared Basmala (none for 1 and 9).
  `path` is the key in the bucket; `url` is that key under --base, the
  public address of the bucket. manifests/recitations.json lists which
  surahs each reciter has.

upload:
- Reads R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY and R2_BUCKET
  from .r2.env (not in git). The key only needs write access to the bucket.
- Skips files already in the bucket, so it can be run again after a fix.
- Then sends the lists that changed (cached 5 minutes, since their names
  stay), only when every file went up, so a list never points at a missing file.
"""
import hashlib
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import imageio_ffmpeg
from mutagen.mp3 import MP3

ROOT = Path(__file__).parent
OUT = ROOT / 'out'
PUB = ROOT / 'publish'
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

RECITERS = {
    'alijon': {'folder': 'Alijon qori qiroati', 'name': 'Alijon Qori'},
}
BITRATE = '96k'
# The source is mastered past full scale (peaks up to 1.2) and MP3 adds more.
# Phones decode to 16 bits and cut off everything above it, which crackles;
# a computer's player decodes in float and hides it. 3 dB down and a limiter
# keep decoded peaks under 0.9 (0.879 at most over all 6237 files).
LEVEL = 'volume=-3dB,alimiter=limit=0.6:level=0'
JOBS = 8  # parallel uploads
BASMALA_FILE = '00. Bismillah.mp3'


def encode(src: Path, dst: Path):
    dst.parent.mkdir(parents=True, exist_ok=True)
    # bitexact: the same input gives the same bytes, so the same name.
    subprocess.run([FFMPEG, '-v', 'error', '-y', '-i', str(src), '-ac', '1', '-af', LEVEL, '-c:a', 'libmp3lame',
                    '-b:a', BITRATE, '-map_metadata', '-1', '-fflags', '+bitexact',
                    '-flags:a', '+bitexact', str(dst)], check=True)


def publish_file(src: Path, stem: str, tmp: Path) -> dict:
    """Encodes src and moves it to its checksum name; returns its manifest entry."""
    encode(src, tmp)
    data = tmp.read_bytes()
    sha = hashlib.sha256(data).hexdigest()
    path = f'{stem}-{sha[:12]}.mp3'
    final = PUB / 'files' / path
    final.parent.mkdir(parents=True, exist_ok=True)
    os.replace(tmp, final)
    return {'path': path, 'size': len(data), 'sha256': sha,
            'duration_ms': round(MP3(final).info.length * 1000)}


def build(slug: str, base: str):
    cfg = RECITERS[slug]
    src = OUT / cfg['folder']
    tmp = PUB / 'tmp'
    tmp.mkdir(parents=True, exist_ok=True)
    jobs = []  # (surah, ayah, source)
    for folder in sorted(p for p in src.iterdir() if p.is_dir() and p.name[:3].rstrip('.').isdigit()):
        surah = int(folder.name.split('.')[0])
        for f in sorted(folder.glob('*.mp3')):
            jobs.append((surah, int(f.name.split('.')[0]), f))
    jobs.append((0, 0, src / BASMALA_FILE))

    def run(job):
        surah, ayah, f = job
        stem = f'{slug}/basmala' if surah == 0 else f'{slug}/{surah:03d}/{ayah:03d}'
        return job, publish_file(f, stem, tmp / f'{surah:03d}_{ayah:03d}.mp3')

    done = {}
    with ThreadPoolExecutor(os.cpu_count()) as pool:
        for n, ((surah, ayah, _), entry) in enumerate(pool.map(run, jobs), 1):
            entry['url'] = f'{base.rstrip("/")}/{entry["path"]}'
            done[(surah, ayah)] = entry
            if n % 500 == 0:
                print(f'  {n}/{len(jobs)}', flush=True)
    tmp.rmdir()

    basmala = done.pop((0, 0))
    out = PUB / 'manifests' / slug
    out.mkdir(parents=True, exist_ok=True)
    surahs = sorted({s for s, _ in done})
    for s in surahs:
        manifest = {
            'reciter': {'slug': slug, 'name': cfg['name']},
            'surah': s,
            'basmala': None if s in (1, 9) else basmala,
            'ayahs': [{'ayah': a, **done[(s, a)]} for (ss, a) in sorted(done) if ss == s],
        }
        (out / f'{s:03d}.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding='utf-8')
    # Which surahs each reciter has, in the shape of `GET /v1/recitations`.
    catalog = PUB / 'manifests' / 'recitations.json'
    reciters = json.loads(catalog.read_text(encoding='utf-8')) if catalog.exists() else []
    reciters = [r for r in reciters if r['slug'] != slug] + [{'slug': slug, 'name': cfg['name'], 'surahs': surahs}]
    catalog.write_text(json.dumps(reciters, ensure_ascii=False), encoding='utf-8')

    # Files of earlier builds that no list points to any more.
    keep = {e['path'] for e in done.values()} | {basmala['path']}
    stale = [p for p in (PUB / 'files' / slug).rglob('*.mp3')
             if p.relative_to(PUB / 'files').as_posix() not in keep]
    for p in stale:
        p.unlink()
    total = sum(e['size'] for e in done.values()) + basmala['size']
    print(f'{len(done)} ayahs + basmala in {len(surahs)} surahs, {total / 1e9:.2f} GB'
          + (f', {len(stale)} old files removed' if stale else ''))


def upload(slug: str):
    import time

    import boto3
    from botocore.config import Config
    env = dict(line.strip().split('=', 1) for line in (ROOT / '.r2.env').read_text().splitlines()
               if '=' in line and not line.lstrip().startswith('#'))
    s3 = boto3.client('s3', endpoint_url=f'https://{env["R2_ACCOUNT_ID"]}.r2.cloudflarestorage.com',
                      aws_access_key_id=env['R2_ACCESS_KEY_ID'],
                      aws_secret_access_key=env['R2_SECRET_ACCESS_KEY'], region_name='auto',
                      config=Config(retries={'max_attempts': 10, 'mode': 'adaptive'},
                                    max_pool_connections=JOBS, connect_timeout=20, read_timeout=120))
    bucket = env['R2_BUCKET']

    existing = set()
    for page in s3.get_paginator('list_objects_v2').paginate(Bucket=bucket, Prefix=f'{slug}/'):
        existing |= {o['Key'] for o in page.get('Contents', [])}
    files = [p for p in (PUB / 'files' / slug).rglob('*.mp3')]
    todo = [p for p in files if p.relative_to(PUB / 'files').as_posix() not in existing]
    print(f'{len(files)} files, {len(files) - len(todo)} already in {bucket}, uploading {len(todo)}', flush=True)

    def put(p: Path):
        # A home connection drops now and then: wait and try the file again.
        for attempt in range(6):
            try:
                return _put(p)
            except Exception:
                if attempt == 5:
                    print(f'  FAILED {p.name}', flush=True)
                    return p
                time.sleep(5 * (attempt + 1))

    def _put(p: Path):
        s3.upload_file(str(p), bucket, p.relative_to(PUB / 'files').as_posix(), ExtraArgs={
            'ContentType': 'audio/mpeg',
            # The name changes with the content, so a file never needs refetching.
            'CacheControl': 'public, max-age=31536000, immutable',
        })

    failed = []
    with ThreadPoolExecutor(JOBS) as pool:
        for n, bad in enumerate(pool.map(put, todo), 1):
            if bad:
                failed.append(bad)
            if n % 500 == 0:
                print(f'  {n}/{len(todo)}', flush=True)
    if failed:
        # The lists go up only once every file they point to is there.
        print(f'{len(failed)} failed, run again to retry them')
        return

    # The lists keep their names, so phones recheck them after 5 minutes.
    etags = {}
    for page in s3.get_paginator('list_objects_v2').paginate(Bucket=bucket, Prefix='manifests/'):
        etags |= {o['Key']: o['ETag'].strip('"') for o in page.get('Contents', [])}
    lists = [PUB / 'manifests' / 'recitations.json', *sorted((PUB / 'manifests' / slug).glob('*.json'))]
    changed = 0
    for p in lists:
        key = p.relative_to(PUB).as_posix()
        if etags.get(key) == hashlib.md5(p.read_bytes()).hexdigest():
            continue
        s3.upload_file(str(p), bucket, key, ExtraArgs={
            'ContentType': 'application/json; charset=utf-8',
            'CacheControl': 'public, max-age=300',
        })
        changed += 1
    print(f'done, {changed} of {len(lists)} lists updated')


if __name__ == '__main__':
    cmd, slug = sys.argv[1], sys.argv[2]
    if cmd == 'build':
        base = sys.argv[sys.argv.index('--base') + 1] if '--base' in sys.argv else 'https://audio.example.com'
        build(slug, base)
    elif cmd == 'upload':
        upload(slug)
