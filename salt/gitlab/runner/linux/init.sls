{%- import_yaml "gitlab/runner/linux/pillars.yaml" as default_vars %}
{% set runner = salt['pillar.get']('gitlab-runner', default_vars.get('gitlab-runner'), merge=True) -%}
{% set registration_tokens = runner.get('registration-tokens') -%}
{% set config = '/etc/gitlab-runner/config.toml' %}
include:
  - gitlab.repo

{%- if salt['file.access'](config, 'f') %}
  {%- for option in runner.get('global-options') %}
    {%- if salt['file.search'](config, option) %}
Change option {{option}}:
  file.line:
    - name: {{config}}
    - content: '{{option}} = {{runner.get('global-options')[option]}}'
    - match: '{{option}} =.*'
    - mode: replace
    {%- else %}
Append option {{option}}:
  file.line:
    - name: {{config}}
    - content: '{{option}} = {{runner.get('global-options')[option]}}'
    - after: check_interval
    - mode: ensure
    {%- endif %}
  {%- endfor %}
{%- else %}
Append option options:
  file.append:
    - name: {{config}}
    - text: |
      {%- for option in runner.get('global-options') %}
        {{option}} = {{runner.get('global-options')[option]}}
      {%- endfor %}
    - makedirs: True
{%- endif %}

Install gitlab-runner:
  pkg.installed:
    - pkgs:
      - gitlab-ci-multi-runner: 9.4.2
      
{%- set user= runner['user']['name']|default('gitlab-runner') %}
Create user {{user}}:
  user.present:
    - name: {{user}}
    - groups:
      {%- for group in runner['user']['groups']|
        default(['docker', 'sudo']) %}
      - {{group}}
      {%- endfor %}
    - require:
      - Install gitlab-runner

Save gitlab-runner options:
  file.managed:
    - name: /etc/gitlab-runner/options
    - contents: |
        {{ runner }}
    - require:
      - Install gitlab-runner

{% for token in registration_tokens %}
  {% for runner in registration_tokens[token] %}
    {%- if runner == 'default' %}
      {%- set runner_name = grains.id %}
    {%- else %}
      {%- set runner_name = grains.id+'___'+runner %}
    {%- endif %}
Registration {{ grains.id }}___{{runner}} runner:
  cmd.run:
    - name: |
        gitlab-ci-multi-runner verify --delete
        gitlab-ci-multi-runner unregister --name {{ runner_name }}
        gitlab-ci-multi-runner register \
        {%- for option in registration_tokens[token][runner] %}
          {%- for value in option %}
          --{{value}}="{{option[value]}}" \
          {%- endfor %}
        {%- endfor %}
          --name={{ runner_name }}
    - env:
      - REGISTRATION_TOKEN: {{token}}
      - REGISTER_NON_INTERACTIVE: 'true'
      - CI_SERVER_URL: '{{salt['pillar.get']('gitlab-runner:agent:url', 'https://gitlab.example.com/ci')}}'
      - RUNNER_BUILDS_DIR: '{{salt['pillar.get']('gitlab-runner:agent:build_disk', '/home/gitlab-runner/disk')}}/builds'
      - RUNNER_CACHE_DIR: '{{salt['pillar.get']('gitlab-runner:agent:build_disk', '/home/gitlab-runner/disk')}}/cache'
      - DOCKER_VOLUMES: '{{salt['pillar.get']('gitlab-runner:agent:build_disk', '/home/gitlab-runner/disk')}}/cache:/cache'
      {%- if salt['file.access']('/usr/bin/gitlab-ci-multi-runner', 'x') and
        not salt['cmd.shell']('(/usr/bin/gitlab-ci-multi-runner verify 2>&1 | grep ERROR)') %}
    - onchanges:
      - Save gitlab-runner options
      {%- endif %}
  {% endfor %}
{% endfor %}
