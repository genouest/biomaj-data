#!/local/python/2.7/bin/python

# Script for Biomaj PostProcess
# author : abretaudeau
# date   : 08/12/2017
# Creation and installation of an environment multi-package with conda.
#usage: python conda_install_multi.py <list of package to install>.txt
#   Do not forget to install/have conda in your biomaj Dockerfile
#   use it with wrapper_install_conda.sh
#   Do not forget to create your package_to_install_list.txt (with one package name per line)


from __future__ import print_function

import os
import sys
import argparse

from subprocess import call

parser = argparse.ArgumentParser()
parser.add_argument('name', help="The name of the env to create, will be used to create the file /local/env/env<name>.sh")
parser.add_argument('listfile', help="A text file containing a list of conda packages to install, with their version (1 package per line, e.g. blast=2.6.0)")
parser.add_argument('dest', help="Location of the environment")
args = parser.parse_args()


dest_env = '%s/env%s.sh' % (args.dest, args.name)

print("Will try to install "+args.name+" with packages in "+args.listfile)

if os.path.exists(dest_env):
    print("Destination env file '%s' already exist" % dest_env, file=sys.stderr)
    return("LOG : Destination env file '%s' already exist" % dest_env, file=sys.stderr)

if not os.path.exists(args.listfile):
    print("Package list file '%s' unreadable" % args.listfile, file=sys.stderr)
    sys.exit(1)

try:
    cmd = "conda info --envs | grep %s > /dev/null" % (args.name)
    print("Executing: %s" % cmd)
    retcode = call(cmd, shell=True)
    if retcode == 0:
        print("Conda env %s already existing" % (args.name), file=sys.stderr)
        sys.exit(1)
except OSError as e:
    print("Execution failed:"+e, file=sys.stderr)
    sys.exit(1)

try:
    cmd = "conda create --name %s --file %s" % (args.name, args.listfile)
    print("Executing: %s" % cmd)
    retcode = call(cmd, shell=True)
    if retcode != 0:
        print("Failed to create conda env %s" % (args.name), file=sys.stderr)
        sys.exit(1)
except OSError as e:
    print("Execution failed:"+e, file=sys.stderr)
    sys.exit(1)

