import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class Lifecycle(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='dotfiles test ')
        self.home = Path(self.tmp.name)
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home/'config space'), XDG_STATE_HOME=str(self.home/'state'))
    def tearDown(self):
        self.tmp.cleanup()
    def run_script(self, name, *args, input=''):
        return subprocess.run(['bash', str(ROOT/name), *args], env=self.env, input=input, text=True, capture_output=True)
    def test_preview_does_not_write(self):
        p = self.run_script('install.sh', '--profile', 'macos', '--dry-run')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('brew', p.stdout)
        self.assertEqual(list(self.home.iterdir()), [])
    def test_links_preserve_existing_and_repeat(self):
        target = self.home/'config space/nvim'
        target.mkdir(parents=True)
        (target/'personal').write_text('keep')
        p = self.run_script('install.sh','--profile','macos','--configs-only')
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(target.resolve(), ROOT/'nvim')
        self.assertTrue(list(self.home.rglob('personal')))
        count = len(list((self.home/'state/dotfiles/backups').glob('*')))
        p = self.run_script('install.sh','--profile','macos','--configs-only')
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(len(list((self.home/'state/dotfiles/backups').glob('*'))),count)
    def test_uninstall_defaults_to_preview_and_requires_confirmation(self):
        p = self.run_script('uninstall.sh','--profile','macos')
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(list(self.home.iterdir()),[])
        p = self.run_script('uninstall.sh','--profile','macos','--apply',input='no\n')
        self.assertNotEqual(p.returncode,0)
        self.assertEqual(list(self.home.iterdir()),[])
    def test_uninstall_moves_config_without_touching_repo(self):
        p = self.run_script('install.sh','--profile','macos','--configs-only')
        self.assertEqual(p.returncode,0,p.stderr)
        p = self.run_script('uninstall.sh','--profile','macos','--apply',input='DELETE\n')
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertFalse((self.home/'config space/nvim').is_symlink())
        self.assertTrue((ROOT/'nvim/init.lua').exists())
        self.assertTrue(list((self.home/'state/dotfiles/backups').rglob('manifest.tsv')))
    def test_wrong_os_rejected(self):
        p=self.run_script('install.sh','--profile','cachyos','--configs-only')
        self.assertNotEqual(p.returncode,0)
        self.assertEqual(list(self.home.iterdir()),[])
    def test_all_profile_previews_are_read_only(self):
        for profile in ['macos','cachyos','server']:
            for script in ['install.sh','uninstall.sh']:
                args=['--profile',profile,'--dry-run','--with-shell','--with-yazi','--with-dev']
                if script=='uninstall.sh': args += ['--packages','--include-shared','--purge-data','--purge-sdkman']
                p=self.run_script(script,*args)
                self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(list(self.home.iterdir()),[])

    def test_linux_package_commands_with_fake_backends(self):
        # Private copy supplies Linux os-release; no production test-only flags.
        import shutil
        fixture=self.home/'repo'
        fixture.mkdir()
        for name in ['install.sh','uninstall.sh','Brewfile','packages','scripts']:
            source=ROOT/name
            if source.is_dir(): shutil.copytree(source,fixture/name)
            else: shutil.copyfile(source,fixture/name)
        for name in ['nvim','tmux','git','lazygit','bat','htop','zsh','nushell','starship','profiles']:
            (fixture/name).symlink_to(ROOT/name)
        osrelease=self.home/'os-release'
        common=fixture/'scripts/common.sh'
        common.write_text(common.read_text().replace('/etc/os-release',str(osrelease).replace(' ',r'\ ')))
        fake=self.home/'fake-bin'; fake.mkdir()
        log=self.home/'commands'
        (fake/'uname').write_text('#!/bin/sh\necho Linux\n')
        for cmd in ['sudo','python3','bat']:
            (fake/cmd).write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$COMMAND_LOG"\n')
        (fake/'dpkg-query').write_text('#!/bin/sh\nprintf "install ok installed"\n')
        (fake/'pacman').write_text('#!/bin/sh\nexit 0\n')
        for file in fake.iterdir(): file.chmod(0o755)
        env=dict(self.env,PATH=str(fake)+':/usr/bin:/bin',COMMAND_LOG=str(log))
        for profile, distro in [('server','ubuntu'),('server','debian'),('cachyos','cachyos')]:
            osrelease.write_text('ID='+distro+'\n')
            args=['bash',str(fixture/'install.sh'),'--profile',profile]
            if profile=='cachyos': args += ['--configs-only']
            p=subprocess.run(args,env=env,text=True,capture_output=True)
            self.assertEqual(p.returncode,0,p.stderr)
            if profile=='server':
                self.assertEqual((self.home/'config space/nvim').resolve(),ROOT/'profiles/server/nvim')
                p=subprocess.run(['bash',str(fixture/'uninstall.sh'),'--profile','server','--packages','--apply'],env=env,input='DELETE\n',text=True,capture_output=True)
                self.assertEqual(p.returncode,0,p.stderr)
        commands=log.read_text()
        self.assertIn('apt-get install',commands)
        self.assertIn('apt-get remove --no-auto-remove',commands)
        self.assertNotIn('autoremove',commands)

    def test_legacy_directory_link_preserves_source(self):
        repository=self.home/'source'
        (repository/'lazygit').mkdir(parents=True)
        source=repository/'lazygit/config.yml'
        source.write_text('original')
        config=self.home/'config space'
        config.mkdir()
        (config/'lazygit').symlink_to(repository/'lazygit')
        command='source "$1"; ROOT="$2"; link_config "$ROOT/lazygit/config.yml" "$CONFIG_HOME/lazygit/config.yml"'
        p=subprocess.run(['bash','-c',command,'test',str(ROOT/'scripts/common.sh'),str(repository)],env=self.env,text=True,capture_output=True)
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertFalse(source.is_symlink())
        self.assertEqual(source.read_text(),'original')

    def test_unknown_option_rejected(self):
        p=self.run_script('install.sh','--not-an-option')
        self.assertNotEqual(p.returncode,0)

if __name__ == '__main__':
    unittest.main()
