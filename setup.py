
from distutils.core import setup
from git import Repo

repo = Repo()

# Get version before adding version file
ver = repo.git.describe('--tags')

# append version constant to package init
with open('python/lcls2_pgp_fw_lib/__init__.py','a') as vf:
    vf.write(f'\n__version__="{ver}"\n')

setup (
   name='lcls2_pgp_fw_lib',
   version=ver,
   packages=['lcls2_pgp_fw_lib',
             'lcls2_pgp_fw_lib/hardware/',
             'lcls2_pgp_fw_lib/hardware/SlacPgpCardG4',
             'lcls2_pgp_fw_lib/hardware/XilinxKcu1500',
             'lcls2_pgp_fw_lib/hardware/shared',],
   package_dir={'':'python'},
)

