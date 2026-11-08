#!/usr/bin/env python3
"""Rebuild skill folders from the bounty skills site.

Reads data/_manifest.json, fetches every payload, writes each file to <out>/<path>.

Usage:
    python rebuild-skills.py --base http://localhost:8080 --out ./skills
"""
import argparse, json, os, sys, urllib.parse, urllib.request


def fetch(url, timeout=60):
    req = urllib.request.Request(url, headers={'User-Agent': 'bounty-skills-rebuild/1.0'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--only', default='')
    ap.add_argument('--timeout', type=int, default=60)
    args = ap.parse_args()
    base = args.base.rstrip('/')
    try:
        manifest = json.loads(fetch(base + '/data/_manifest.json', args.timeout).decode('utf-8'))
    except Exception as e:
        print('FATAL: cannot read manifest: %s' % e, file=sys.stderr)
        return 2
    total = written = 0
    failed = []
    for entry in manifest:
        rel = entry['path']
        if args.only and not rel.startswith(args.only):
            continue
        total += 1
        url = base + '/data/' + urllib.parse.quote(entry['id']) + '.json'
        try:
            payload = json.loads(fetch(url, args.timeout).decode('utf-8'))
        except Exception as e:
            failed.append(rel)
            print('FAIL  %s  (%s)' % (rel, e))
            continue
        dest = os.path.join(args.out, rel.replace('/', os.sep))
        parent = os.path.dirname(dest)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(dest, 'w', encoding='utf-8', newline='') as fh:
            fh.write(payload.get('content', ''))
        written += 1
        if written % 200 == 0:
            print('  %d/%d' % (written, total))
    print('')
    print('wrote %d of %d file(s) to %s' % (written, total, args.out))
    if failed:
        print('failed: %d' % len(failed), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())