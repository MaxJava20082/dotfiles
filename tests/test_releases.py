import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

spec=importlib.util.spec_from_file_location('release',Path(__file__).resolve().parents[1]/'scripts/release_binary.py')
release=importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)

class Releases(unittest.TestCase):
    def archive(self, name='../../lazygit', symlink=False):
        data=io.BytesIO()
        with tarfile.open(fileobj=data,mode='w:gz') as archive:
            info=tarfile.TarInfo(name)
            if symlink:
                info.type=tarfile.SYMTYPE; info.linkname='/etc/passwd'
                archive.addfile(info)
            else:
                info.size=6; archive.addfile(info,io.BytesIO(b'binary'))
        return data.getvalue()
    def test_current_lazygit_asset_names(self):
        self.assertTrue(release.asset_match('lazygit','lazygit_0.66.3_linux_x86_64.tar.gz','x86_64'))
        self.assertTrue(release.asset_match('lazygit','lazygit_0.66.3_linux_arm64.tar.gz','aarch64'))
        self.assertFalse(release.asset_match('lazygit','lazygit_0.66.3_darwin_arm64.tar.gz','aarch64'))
    def test_archive_paths_are_never_extracted(self):
        self.assertEqual(release.executable_from_archive(self.archive(),'a.tar.gz','lazygit'),b'binary')
    def test_symlink_executable_rejected(self):
        with self.assertRaises(ValueError):
            release.executable_from_archive(self.archive(symlink=True),'a.tar.gz','lazygit')
    def test_verified_install_and_mismatch(self):
        data=self.archive()
        asset={'name':'lazygit_0.66.3_linux_x86_64.tar.gz','digest':'sha256:'+hashlib.sha256(data).hexdigest(),'browser_download_url':'https://example.invalid/archive'}
        metadata={'tag_name':'v0.66.3','assets':[asset]}
        with tempfile.TemporaryDirectory() as home, patch.object(release.platform,'machine',return_value='x86_64'):
            with patch.object(release,'fetch',side_effect=[json.dumps(metadata).encode(),data]):
                release.main('lazygit',home)
            target=Path(home)/'lazygit'
            self.assertEqual(target.read_bytes(),b'binary')
            self.assertEqual(target.stat().st_mode & 0o777,0o755)
            with patch.object(release,'fetch',side_effect=[json.dumps(metadata).encode(),b'bad']):
                with self.assertRaisesRegex(ValueError,'SHA256 mismatch'):
                    release.main('lazygit',home)
            self.assertEqual(target.read_bytes(),b'binary')

if __name__=='__main__': unittest.main()
