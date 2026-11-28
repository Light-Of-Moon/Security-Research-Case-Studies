#!/usr/bin/env python3
"""Fetch official control artwork and switch the root README to local image paths."""
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "assets/logos/controls"
LOGOS = {'owasp-crs-official.png': 'https://owasp.org/www-project-modsecurity-core-rule-set/assets/images/logo.png', 'suricata-official.png': 'https://suricata.io/wp-content/uploads/2023/09/Logo-Suricata-horiz-R.png', 'wazuh-official.png': 'https://wazuh.com/uploads/2022/05/Logo-blogpost.png', 'docker-official.png': 'https://www.docker.com/app/uploads/2026/02/Docker_Logo_660x400.png'}

def main():
    readme = ROOT / "README.md"
    original = readme.read_text(encoding="utf-8")
    pending = {}
    for filename, url in LOGOS.items():
        with urlopen(Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=30) as response:
            data = response.read(10_000_001)
        if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) > 10_000_000:
            raise ValueError(f"Unexpected image data: {url}")
        pending[filename] = data
    TARGET.mkdir(parents=True, exist_ok=True)
    for filename, data in pending.items():
        (TARGET / filename).write_bytes(data)
        original = original.replace(f'src="{LOGOS[filename]}"', f'src="assets/logos/controls/{filename}"')
    readme.write_text(original, encoding="utf-8")
    print("Official logos saved and README updated.")

if __name__ == "__main__":
    main()
