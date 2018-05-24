{%- if grains.kernel == 'Linux' %}
Apt packages for correct work Gitlab repo:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - ca-certificates
    - allow_updates: True
    - skip_verify: True
    - install_recommends: False

{%- set sources_list = '/etc/apt/sources.list.d/gitlab_com.list' %}
{%- if not salt['file.access'](sources_list,'f') %}
Setup Gitlab deb repo:
  pkgrepo.managed:
    - humanname: GitLab repo
    - name: deb https://packages.gitlab.com/runner/gitlab-ci-multi-runner/{{ grains.os|lower }}/ {{ grains.oscodename }} main
    - file: {{sources_list}}
    - refresh_db: False
    - require:
      - Apt packages for correct work Gitlab repo

Setup Gitlab deb-src repo:
  pkgrepo.managed:
    - humanname: GitLab repo
    - name: deb-src https://packages.gitlab.com/runner/gitlab-ci-multi-runner/{{ grains.os|lower }}/ {{ grains.oscodename }} main
    - file: {{sources_list}}
    - refresh_db: True
    - gpgcheck: 1
    - key_url: https://packages.gitlab.com/gpg.key
    - require:
      - Apt packages for correct work Gitlab repo
{%- endif %}

{%- endif %}
