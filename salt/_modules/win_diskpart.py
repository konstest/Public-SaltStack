#!/usr/bin/env python
# coding=utf-8

import logging
import os
import time
import re

# Get logging started
log = logging.getLogger(__name__)

def exec_list_commands(list_commands):
    '''
    Sequence execute list of commands by adding them into tmp file and
    run diskpart /s C:\\salt\\var\\cache\\salt\\minion\\diskpart.txtTIMEMARKER
    Example of using:
        salt minion_name win_diskpart.exec_list_commands ['list disk']
    '''
    filename = 'C:\\salt\\var\\cache\\salt\\minion\\diskpart.txt{}'.format(time.time())
    cmd = 'diskpart /s {}'.format(filename)
    with open(filename, 'a') as tmp_file:
        for command in list_commands:
            tmp_file.write('{}\n'.format(command))
    msg = __salt__['cmd.shell'](cmd)
    os.remove(filename)
    return msg


def list_disks():
    '''
    Get dict of phisical disks on Windows host
    Example of using:
        salt minion_name win_diskpart.list_disks
    '''
    diskpart_output = exec_list_commands(['list disk'])

    lines = []
    for line in diskpart_output.split('\n'):
        line = line.strip()
        if re.match('^Disk', line):
            lines.append(line)

    if len(lines) > 1:
        lines.pop(0) # remove: Disk ###  Status         Size     Free     Dyn  Gpt

        disks = {}
        for line in lines:
            disk = {
                    line[:8].strip(): {
                        'Status': line[10:23].strip(),
                        'Size': line[25:32].strip(),
                        'Free': line[34:41].strip(),
                        'Dyn': line[43:46].strip(),
                        'Gpt': line[48:].strip()
                    }
            }
            disks.update(disk)
        return disks

    return False



def list_volumes():
    '''
    Get dict of volumes on Windows host
    Example of using:
        salt minion_name win_diskpart.list_volumes
    '''
    diskpart_output = exec_list_commands(['list volume'])

    lines = []
    for line in diskpart_output.split('\n'):
        line = line.strip()
        if re.match('^Volume', line):
            lines.append(line)

    if len(lines) > 1:
        lines.pop(0) # remove: Disk ###  Status         Size     Free     Dyn  Gpt

        volumes = {}
        for line in lines:
            volume = {
                    line[:10].strip(): {
                        'Ltr': line[12:15].strip(),
                        'Label': line[17:28].strip(),
                        'Fs': line[30:35].strip(),
                        'Type': line[37:47].strip(),
                        'Size': line[49:56].strip(),
                        'Status': line[58:67].strip(),
                        'Info': line[69:].strip()
                    }
            }
            volumes.update(volume)
        return volumes

    return False
