{%- set upgrade_on_boot = pillar.get('upgrade_on_boot') %}
{%- set version = pillar.get('version') %}

systemd service:
  file.managed:
    - name: /etc/systemd/system/upgrade-128t-onboot.service
    - source: salt://files/upgrade-128t-onboot.service
    - mode: 644
    - user: root
    - group: root

enable service:
  service.enabled:
    - name: upgrade-128t-onboot

upgrade script:
  file.managed:
    - name: /usr/bin/upgrade128t.sh
    - source: salt://files/upgrade128t.sh
    - mode: 744
    - user: root
    - group: root

environment:
  file.managed:
    - name: /etc/128technology/128tupgrade_on_next_boot
    - template: jinja
    - contents:
      -  UPGRADE_ON_BOOT={{ pillar['upgrade_on_boot'] }}
      -  VERSION="{{ pillar['version'] }}"
