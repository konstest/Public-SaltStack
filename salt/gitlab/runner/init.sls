# Copy this folder and name as you want
# change SLS_PREFIX to your path(state-name without init)
{% set SLS_PREFIX="gitlab.runner"%}

# Windows or Linux choice
{% if grains['kernel'] == 'Windows' %}
include:
    - {{ SLS_PREFIX }}.windows

{% elif grains['kernel'] == 'Linux' %}
include:
    - {{ SLS_PREFIX }}.linux

{% endif %}
