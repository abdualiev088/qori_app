"""Copies the whole audio bucket from one Cloudflare R2 account to another.

    python migrate_r2.py            # dry run: counts what would be copied
    python migrate_r2.py --copy     # copies

- Source: .r2.env (R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET).
- Destination: .r2.dest.env, the same four keys plus R2_PUBLIC_URL (the new
  bucket's public address, e.g. https://pub-….r2.dev). Not in git.
- Every object keeps its Content-Type and Cache-Control. Objects already in the
  destination with the same size are skipped, so a broken run can be repeated.
- Manifests (manifests/*.json) hold absolute file URLs: the old public address
  is replaced by R2_PUBLIC_URL, so the app reads files from the new bucket.
  They go last, once every file is there, so a list never points at a missing file.
"""
import json
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import boto3

ROOT = Path(__file__).parent
OLD_PUBLIC_URL = 'https://pub-4158057f334347aba656f785e7219ec1.r2.dev'
JOBS = 16


def read_env(name: str) -> dict:
    env = {}
    for line in (ROOT / name).read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            key, value = line.split('=', 1)
            env[key.strip()] = value.strip()
    return env


def client(env: dict):
    return boto3.client('s3', endpoint_url=f'https://{env["R2_ACCOUNT_ID"]}.r2.cloudflarestorage.com',
                        aws_access_key_id=env['R2_ACCESS_KEY_ID'], aws_secret_access_key=env['R2_SECRET_ACCESS_KEY'],
                        region_name='auto')


def listing(s3, bucket: str) -> dict:
    sizes = {}
    for page in s3.get_paginator('list_objects_v2').paginate(Bucket=bucket):
        for obj in page.get('Contents', []):
            sizes[obj['Key']] = obj['Size']
    return sizes


def main():
    copy = '--copy' in sys.argv
    src_env, dst_env = read_env('.r2.env'), read_env('.r2.dest.env')
    new_url = dst_env['R2_PUBLIC_URL'].rstrip('/')
    src, dst = client(src_env), client(dst_env)
    src_bucket, dst_bucket = src_env['R2_BUCKET'], dst_env['R2_BUCKET']

    have = listing(src, src_bucket)
    there = listing(dst, dst_bucket)
    manifests = sorted(k for k in have if k.endswith('.json'))
    files = sorted(k for k in have if not k.endswith('.json') and there.get(k) != have[k])
    total_mb = sum(have[k] for k in files) / 1e6
    print(f'source: {len(have)} objects, {sum(have.values()) / 1e6:.1f} MB')
    print(f'to copy: {len(files)} files ({total_mb:.1f} MB) + {len(manifests)} manifests')
    if not copy:
        print('dry run; add --copy to copy')
        return

    def put(key: str, body: bytes, head: dict):
        extra = {k: head[k] for k in ('ContentType', 'CacheControl') if head.get(k)}
        dst.put_object(Bucket=dst_bucket, Key=key, Body=body, **extra)

    done = 0

    def copy_file(key: str):
        nonlocal done
        obj = src.get_object(Bucket=src_bucket, Key=key)
        put(key, obj['Body'].read(), obj)
        done += 1
        if done % 250 == 0:
            print(f'  {done}/{len(files)}', flush=True)

    with ThreadPoolExecutor(JOBS) as pool:
        list(pool.map(copy_file, files))  # list() re-raises the first error

    for key in manifests:
        obj = src.get_object(Bucket=src_bucket, Key=key)
        text = obj['Body'].read().decode('utf-8').replace(OLD_PUBLIC_URL, new_url)
        json.loads(text)  # still valid JSON
        put(key, text.encode('utf-8'), obj)

    after = listing(dst, dst_bucket)
    missing = [k for k in have if k not in after]
    print(f'destination: {len(after)} objects; missing: {len(missing)}')
    if missing:
        print('\n'.join(missing[:20]))
        sys.exit(1)


if __name__ == '__main__':
    main()
