{%- set pillar_disk = salt.pillar.get('disk:extend:windows', {}) %}
Rescan new disks and new space:
  module.run:
    - name: win_diskpart.exec_list_commands
    - list_commands:
      - rescan

{%- for disk_id, description in salt.win_diskpart.list_disks().iteritems() %}
{%- set disk_detail = salt.win_diskpart.exec_list_commands(["select "~disk_id, "detail disk"]) %}
{%- if 'There are no volumes.' in disk_detail.split('\n') %}  {#- <-- It means that HDD was not initialized #}
  {%- if disk_id in pillar_disk %}
  {%- set Ltr = pillar_disk[disk_id].get('Ltr') %}
  {%- set Label = pillar_disk[disk_id].get('Label') %}
  {%- set MountDir = pillar_disk[disk_id].get('MountDir') %}

  {%- if MountDir %}
Preporation gitlab-runner build dir for mount point:
  file.directory:
    - name: '{{MountDir}}'
    - makedirs: True
    - win_inheritance: True
  {%- endif %}

Initialization disk {{Ltr}} with label {{Label}}:
  module.run:
    - name: win_diskpart.exec_list_commands
    - list_commands:
      - select {{disk_id}}
      - attributes disk clear readonly noerr
      - online disk noerr
      - convert mbr noerr
      - create partition primary noerr
      {%- if Label %}
      - format quick fs=ntfs Label="{{Label}}" noerr
      {%- else %}
      - format quick fs=ntfs noerr
      {%- endif %}
      {%- if Ltr %}
      - assign letter={{Ltr}} noerr
      {%- elif MountDir %}
      - assign mount="{{MountDir}}" noerr
    - require:
      - Preporation gitlab-runner build dir for mount point
      {%- endif %}
      {%- if Ltr and MountDir %}
ERROR!!! You can't assign disk a LETTER and a mount point dir, simultaneously
      {%- endif %}

  {%- endif %}
{%- endif %}
{%- endfor %}

{%- for volume, description in salt.win_diskpart.list_volumes().iteritems() %}
{%- if description['Ltr'] != '' %}
Extend disk {{description['Ltr']}}:
  module.run:
    - name: win_diskpart.exec_list_commands
    - list_commands:
      - select volume {{description['Ltr']}}
      - extend noerr
{%- endif %}
{%- endfor %}
