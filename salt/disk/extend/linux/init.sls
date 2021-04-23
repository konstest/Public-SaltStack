{% import_yaml slspath.replace('.','/')~"/pillars.yaml" as variables_yaml %}
{% set pillar_disk = salt['pillar.get']('disk', variables_yaml.get('disk'), merge=True) -%}
{#- Scan new disks  in backgrounp mode #}
{% do salt.cmd.shell('ls /sys/class/scsi_host | grep -E  host[0-9] | while read HostX; do echo "- - -" > /sys/class/scsi_host/$HostX/scan; done') %}
{% do salt.cmd.shell('ls /sys/class/block/ | grep sd[a-z]$ | while read DISK; do echo "1" > /sys/class/block/$DISK/device/rescan; done') %}

{%- if salt.cmd.shell('which parted') %}
  {%- set block_devices = salt['partition.get_block_device']() %}
  
  {%- for dev in block_devices %}
    {%- if 'sd' in dev %}
    {%- set disk = "/dev/"~dev %}
    {%- set disk_partitions = salt.partition.list(disk) %}
    {%- if disk_partitions.get('info').get('partition table') == 'loop' %} {#- Check if disk has't partitions #}
Extend filesystem on {{disk}} disk entirely:
  cmd.run:
    - name: e2fsck -f {{disk}}; resize2fs {{disk}}
    {%- else %}
      {%- set list_part_numbers = disk_partitions.partitions.keys()|sort %}      
      {%- if list_part_numbers != [] %}
        {%- set last_part_number = list_part_numbers[-1] %}      
        {%- set disk_partition = disk~last_part_number %}
        {%- set new_size = disk_partitions.info.size %}
        {%- set old_size = disk_partitions.partitions[last_part_number]['size'] %}
        {%- if old_size.replace('GB','')|float < new_size.replace('GB','')|float %}
Extend only last partition {{disk_partition}} from {{old_size}} to {{new_size}}:
  cmd.run:
    - name: parted -ms {{disk}} resizepart {{last_part_number}} {{new_size}} || (parted -ms {{disk}} resizepart {{list_part_numbers[-1]}} 100% && parted -ms {{disk}} resizepart {{last_part_number}} 100%) && partprobe -s
          {%- if 'lvm' in disk_partitions.partitions[last_part_number]['flags'] %}
Extend physical LVM volume on {{disk_partition}}:
  cmd.run:
    - name: pvresize {{disk_partition}}
            {%- set lvm = pillar_disk.extend.lvm %}
            {% if lvm.get(disk_partition) %}
Extend logical LVM volume {{lvm[disk_partition]}} on {{disk_partition}}:
  cmd.run:
    - name: lvresize {{lvm[disk_partition]}} {{disk_partition}} && resize2fs {{lvm[disk_partition]}}
            {%- endif %}
          {%- endif %}
          {%- if 'type' in disk_partitions.partitions[last_part_number] and 'ext' in disk_partitions.partitions[last_part_number]['type'] or
          'file system' in disk_partitions.partitions[last_part_number] and 'ext' in disk_partitions.partitions[last_part_number]['file system'] %}
Extend {{disk_partitions.partitions[last_part_number]['type']}} filesystem on {{disk}}{{last_part_number}} from {{old_size}} to {{new_size}}:
  cmd.run:
    - name: pvresize {{disk}}{{last_part_number}}
          {%- endif %}

        {%- endif %}
      {%- endif %}
    {%- endif %}
    {%- endif %} {#- if 'sd' in dev #}
  {%- endfor %}
  
{%- endif %}
parted:
  pkg.installed
