import os.path
import wget
import datetime
import iptc

from threading import local
from pathlib import Path

remote_blacklist_file = 'http://lists.blocklist.de/lists/all.txt'
local_blacklist_file = 'iptables_blacklist_file'

def console_logger (str_message):
    date_today = datetime.datetime.now()
    print('[ ' + date_today.strftime("%Y-%m-%d %H:%M:%S") + ' ] ' + ' | ' + str_message)

def download_blacklist ():
    if os.path.exists(local_blacklist_file):
        os.remove(local_blacklist_file)
        wget.download(remote_blacklist_file, local_blacklist_file)
    else:
        wget.download(remote_blacklist_file, local_blacklist_file)

def iptables_engine ():
    if not os.path.exists(local_blacklist_file):
        console_logger(remote_blacklist_file + ' not found. Please be sure your machine is connected to the internet to download the latest backlist database.')
        quit()

    file_blacklist = open(local_blacklist_file, 'r')
    file_lines = file_blacklist.readlines()

    for file_single_line in file_lines:
        print(file_single_line)
        # needs more magic here - wip
        # $objIPTables -A $objDropListName -i ${objPublicInterface} -s $strIPAddress -j LOG --log-prefix " Drop Bad IP List "
	    # $objIPTables -A $objDropListName -i ${objPublicInterface} -s $strIPAddress -j DROP
    
    return True    

def disposal ():
    os.remove(local_blacklist_file)
    console_logger(local_blacklist_file + ' are removed successfully.')

def main ():
    download_blacklist()
    iptables_engine()

    if iptables_engine :
        disposal()

main()