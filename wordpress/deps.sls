{% from "wordpress/map.jinja" import map with context %}

# Verifying package dependencies and services. I do not know package names
# for non-SUSE, so the conditional is to prevent breakage with other distros.
# This shoud be templated across all distros and then remove the 'if' statmement

{% if grains.os_family == "Suse" %}
web-server:
  pkg.installed:
    - pkgs:
      - {{ map.web_server }}
      - {{ map.web_php }}
  service.running:
    - name: {{ map.web_service }}
    - enable: True

db-server:
  pkg.installed:
    - name: {{ map.database }}
  service.running:
    - name: {{ map.db_service }}
    - enable: True

cli-deps:
  pkg.installed:
    - pkgs:
{% for clidep in map.cli_dep %}
      - {{ clidep }}
{% endfor %}
{% endif  %}

