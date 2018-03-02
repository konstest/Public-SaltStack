#!/usr/bin/env python
# coding=utf-8

import yaml

conf_file = "ext_pillar.conf"
with open(conf_file, 'r') as f:
    ext_pillar = yaml.safe_load(f.read())

try:
    print(ext_pillar['ext_pillar'][0])
except Exception as e:
    print(e)
