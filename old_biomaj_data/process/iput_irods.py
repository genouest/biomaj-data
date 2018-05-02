#!/usr/bin/env python3
from irods.models import Collection, DataObject
from irods.session import iRODSSession
import getopt
import sys
import os

#usage : python iput_irods.py -f <file> -p <path_on_iRODS_zone> -u <iRODS_user> -a <iRODS_user_password> -r 1247 -z <iRODS_zone> -s <iRODS_host_name>
#Do not forget BioMAJ version with irods and to install python-irodsclient
new_directory=""

def usage():
    usage= """
    ################################
        Put files on iRODS server
    ################################
    
    python iput_irods -f <file_to_put_on_irods> -p <path_on_irods> -u <irods_user> -a <irods_password> -r 1247 -z <ZONE> -s 10.0.0.1
    -h --help : print this message
    -f --file : file to push on iRODS
    -p --path : path on iRODS zone (example: /Zone/home/user)
    -u --irods_user : name of the user on iRODS
    -a --password : password of the iRODS user
    -r --port : iRODS port
    -z --zone : name of the iRODS zone
    -s --server : addresse of the iRODS server (local, or host name)
    -c --create_directory : directory of the file on irods server
    """
    print(usage)

try:
    opts, args = getopt.getopt(sys.argv[1:],"h:f:p:u:a:r:z:s:c:",["help","file=","path=","irods_user=","password=","port=","zone=","server=","create_directory="])
    if not opts:
        usage()
        sys.exit(2)
except getopt.GetoptError as e:
    print(e)
    usage()
    sys.exit(2)
for opt, arg in opts : 
    if opt in ("-h", "--help"):
        usage()
        sys.exit(2)
    elif opt in ("-f","--file"):
        file_to_put = arg
    elif opt in ("-p","--path"):
        path = arg
    elif opt in ("-u","--irods_user"):
        irods_user = arg
    elif opt in ("-a","--password"):
        password = arg
    elif opt in ("-r","--port"):
        port = arg
    elif opt in ("-z","--zone"):
        zone = arg
    elif opt in ("-s","--server"):
        server = arg
    elif opt in ("-c","--create_directory"):
        new_directory = arg
    else:
        print("Unkwnown option {} ".format(opt))
        usage()
        sys.exit(2)


class ExceptionIRODS(Exception):
    def __init__(self, exception_reason):
        self.exception_reason = exception_reason

    def __str__(self):
        return self.exception_reason
        
#####################################################################
if __name__ == '__main__':
    try:
        session = iRODSSession(host=server, port=port, user=irods_user, password=password, zone=zone)
    except ExceptionIRODS as e:
        print("iRODSError:" + str(e))

    try:
         # Check if the collection path exists
         coll=session.collections.get(new_directory)
         path=path+"/"+str(new_directory)
    except:
         try: # New option with recursive creation : not active 07/03/2018
             session.collections.create(new_directory, recurse=True)
         except: # Create the repertory one by one
             directory_list=new_directory.split('/')
             for directory in directory_list:
                 # is the directory exist on iRODS?
                 try:
                     if directory !='':
                         coll=session.collections.get(path+"/"+str(directory))
                         path=path+"/"+str(directory)
                 except:
                     if directory != '':
                         coll = session.collections.create(path+"/"+str(directory))
                         path=path+"/"+str(directory)
    finally:
        try:
            session.data_objects.put(file_to_put, path+'/')
            print("###The file "+str(file_to_put)+" is on iRODS in "+str(path)+".")
        except ExceptionIRODS as e:
            print("iRODSError:" + str(e))

    session.cleanup()

