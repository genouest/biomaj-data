import os
from os import listdir
from os.path import isfile, join
import shutil
import logging

def list():
    '''
    Get available example banks
    '''
    dir_path = os.path.dirname(os.path.realpath(__file__))
    propsDir = join(dir_path, '..', 'db_properties')
    for f in listdir(propsDir):
        onlyfiles = [f.replace('.properties', '') for f in listdir(propsDir) if (isfile(join(propsDir, f)) and f.endswith('.properties'))]
    return onlyfiles

def importTo(bank, to_dir):
    dir_path = os.path.dirname(os.path.realpath(__file__))
    propsDir = join(dir_path, '..', 'db_properties')
    bank_file = join(propsDir, bank + '.properties')
    if not os.path.exists(bank_file):
        logging.error('Bank does not exists')
        return (True, 'Bank does not exists')
    shutil.copyfile(bank_file, join(to_dir, bank + '.properties'))
    return (False, join(to_dir, bank + '.properties'))
    
