{% import_yaml slspath.replace('.','/')~"/pillars.yaml" as variables_yaml %}
{% set pillar_disk = salt['pillar.get']('disk', variables_yaml.get('disk'), merge=True) -%}
{#- Scan new disks  in backgrounp mode #}
{% do salt.cmd.shell('ls /sys/class/scsi_host | grep -E  host[0-9] | while read HostX; do echo "- - -" > /sys/class/scsi_host/$HostX/scan; done') %}
{% do salt.cmd.shell('ls /sys/class/block/ | grep sd[a-z]$ | while read DISK; do echo "1" > /sys/class/block/$DISK/device/rescan; done') %}

{%- if salt.cmd.shell('which parted') %}
  {%- set block_devices = salt['partition.get_block_device']() %}
  
  {%- for disk in block_devices %}
    {%- set disk = "/dev/"~disk %}
    {%- set disk_partitions = salt.partition.list(disk) %}
    {%- if disk_partitions.info['partition table'] == 'loop' %} {#- Check if disk has't partitions #}
Extend filesystem on {{disk}} disk entirely:
  cmd.run:
    - name: resize2fs {{disk}}
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
    - name: parted -ms {{disk}} resizepart {{last_part_number}} {{new_size}} && partprobe -s
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
          {%- if 'ext' in disk_partitions.partitions[last_part_number]['type'] %}
Extend {{disk_partitions.partitions[last_part_number]['type']}} filesystem on {{disk}}{{last_part_number}} from {{old_size}} to {{new_size}}:
  cmd.run:
    - name: pvresize {{disk}}{{last_part_number}}
          {%- endif %}
        {%- endif %}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
  
{%- endif %}
