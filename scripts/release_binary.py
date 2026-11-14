#!/usr/bin/env python3
"""Install a Linux CLI from official GitHub Releases, verifying API SHA256.

Only the requested executable is extracted, never archive paths or symlinks.
"""
import hashlib
import io
import json
import os
from pathlib import Path
import platform
import sys
import tarfile
import tempfile
import urllib.request
import zipfile

REPOS = {'lazygit': 'jesseduffield/lazygit', 'nu': 'nushell/nushell',
         'starship': 'starship/starship', 'eza': 'eza-community/eza', 'yazi': 'sxyazi/yazi'}


def asset_match(tool, name, arch):
    machine = {'x86_64': 'x86_64', 'aarch64': 'aarch64', 'arm64': 'aarch64'}.get(arch)
    if not machine:
        raise ValueError('Supported architectures: x86_64, aarch64')
    if tool == 'lazygit':
        return name.lower().endswith(f'linux_{"arm64" if machine == "aarch64" else machine}.tar.gz')
    if tool == 'nu':
        return name.endswith(f'{machine}-unknown-linux-gnu.tar.gz')
    if tool == 'starship':
        return name == f'starship-{machine}-unknown-linux-musl.tar.gz'
    if tool == 'eza':
        return name == f'eza_{machine}-unknown-linux-gnu.tar.gz'
    return name == f'yazi-{machine}-unknown-linux-gnu.zip'


def executable_from_archive(data, name, executable):
    if name.endswith('.zip'):
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            matches = [i for i in archive.infolist() if Path(i.filename).name == executable and not i.is_dir()
                       and (i.external_attr >> 16) & 0o170000 != 0o120000]
            if len(matches) != 1:
                raise ValueError('Expected exactly one executable in release archive')
            return archive.read(matches[0])
    with tarfile.open(fileobj=io.BytesIO(data), mode='r:gz') as archive:
        matches = [i for i in archive.getmembers() if Path(i.name).name == executable and i.isfile()]
        if len(matches) != 1:
            raise ValueError('Expected exactly one executable in release archive')
        return archive.extractfile(matches[0]).read()


def fetch(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'dotfiles-installer', 'Accept': 'application/vnd.github+json' if '/api.github.com/' in url else 'application/octet-stream'})
    with urllib.request.urlopen(req, timeout=120) as response:
        return response.read()


def main(tool, destination):
    repo = REPOS[tool]
    release = json.loads(fetch(f'https://api.github.com/repos/{repo}/releases/latest'))
    assets = [a for a in release['assets'] if asset_match(tool, a['name'], platform.machine())]
    if len(assets) != 1:
        raise ValueError(f'No unique Linux asset for {tool}/{platform.machine()}')
    asset = assets[0]
    digest = asset.get('digest') or ''
    if not digest.startswith('sha256:'):
        raise ValueError('GitHub asset has no SHA256 digest; refusing unverified installation')
    data = fetch(asset['browser_download_url'])
    if hashlib.sha256(data).hexdigest() != digest.split(':', 1)[1]:
        raise ValueError('Release SHA256 mismatch')
    binary = executable_from_archive(data, asset['name'], tool)
    target = Path(destination).expanduser()/tool
    target.parent.mkdir(parents=True, exist_ok=True)
    # Caller backs up pre-existing binaries before invoking this helper.
    if target.exists() or target.is_symlink():
        raise ValueError(f'Destination already exists: {target}')
    fd, temporary = tempfile.mkstemp(dir=target.parent, prefix=f'.{tool}.')
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(binary)
        os.chmod(temporary, 0o755)
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(f'{tool}: {release["tag_name"]} → {target}')


if __name__ == '__main__':
    try:
        main(*sys.argv[1:])
    except Exception as error:
        sys.exit(str(error))
