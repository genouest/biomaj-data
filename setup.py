try:
    from setuptools import setup, find_packages
except ImportError:
    from distutils.core import setup
from distutils.command.install import install
import os


here = os.path.abspath(os.path.dirname(__file__))
try:
    with open(os.path.join(here, 'README.md')) as f:
        README = f.read()
except UnicodeDecodeError:
    with open(os.path.join(here, 'README.md'), encoding='utf-8') as f:
        README = f.read()

config = {
    'description': 'BioMAJ data examples',
    'long_description': README,
    'author': 'Olivier Sallou',
    'url': 'https://github.com/genouest/biomaj-data',
    'author_email': 'olivier.sallou@irisa.fr',
    'version': '3.1.2',
     'classifiers': [
        # How mature is this project? Common values are
        #   3 - Alpha
        #   4 - Beta
        #   5 - Production/Stable
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Natural Language :: English',
        'Operating System :: POSIX :: Linux',
        # Indicate who your project is intended for
        'Intended Audience :: Science/Research',
        'Topic :: Scientific/Engineering :: Bio-Informatics',
        # Pick your license as you wish (should match "license" above)
        'License :: OSI Approved :: GNU Affero General Public License v3 or later (AGPLv3+)',
        # Specify the Python versions you support here. In particular, ensure
        # that you indicate whether you support Python 2, Python 3 or both.
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4'
    ],
    'install_requires': ['biomaj-core'],
    'packages': find_packages(),
    'include_package_data': True,
    'name': 'biomaj_data',
}

setup(**config)
