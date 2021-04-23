**disk.extend**
1. This formula doing automatic extending exsting disks and their partitions. 
2. Extend Linux filesystem and LVM volume. For LVM you need point by hand in pillars 
what disk & LVM volume you need to resize. Example of pillars presented in [disk/extend/linux/pillars.yaml](https://gitlab..com/scm/Public-SaltStack/blob/master/formulas/states/disk/extend/linux/pillars.yaml)
3. Extend Windows disks and volumes on new accessible place. Also assign disk letter from pillar parameters, example [disk/extend/windows/pillars.yaml](https://gitlab..com/scm/Public-SaltStack/blob/master/formulas/states/disk/extend/windows/pillars.yaml)