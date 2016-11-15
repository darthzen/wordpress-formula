{% from "wordpress/map.jinja" import map with context %}

include:
  - wordpress.cli

# Verifying package dependencies and services. I do not know package names
# for non-SUSE, so the conditional is to prevent breakage with other distros.
# This shoud be templated across all distros

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


{% for id, site in salt['pillar.get']('wordpress:sites', {}).items() %}
{{ map.docroot }}/{{ id }}:
  file.directory:
    - user: {{ map.www_user }}
    - group: {{ map.www_group }}
    - mode: 755
    - makedirs: True

# This command tells wp-cli to download wordpress
download_wordpress_{{ id }}:
 cmd.run:
  - cwd: {{ map.docroot }}/{{ id }}
  - name: '/usr/local/bin/wp core download --path="{{ map.docroot }}/{{ id }}/"'
  - user: {{ map.www_user }}
  - unless: test -f {{ map.docroot }}/{{ id }}/wp-config.php

# This command tells wp-cli to create our wp-config.php, DB info needs to be the same as above
configure_{{ id }}:
 cmd.run:
  - name: '/usr/local/bin/wp core config --dbname="{{ site.get('database') }}" --dbuser="{{ site.get('dbuser') }}" --dbpass="{{ site.get('dbpass') }}" --dbhost="{{ site.get('dbhost') }}" --path="{{ map.docroot }}/{{ id }}"'
  - cwd: {{ map.docroot }}/{{ id }}
  - user: {{ map.www_user }}
  - unless: test -f {{ map.docroot }}/{{ id }}/wp-config.php  

# This command tells wp-cli to install wordpress
install_{{ id }}:
 cmd.run:
  - cwd: {{ map.docroot }}/{{ id }}
  - name: '/usr/local/bin/wp core install --url="{{ site.get('url') }}" --title="{{ site.get('title') }}" --admin_user="{{ site.get('username') }}" --admin_password="{{ site.get('password') }}" --admin_email="{{ site.get('email') }}" --path="{{ map.docroot }}/{{ id }}/"'
  - user: {{ map.www_user }}
  - unless: /usr/local/bin/wp core is-installed --path="{{ map.docroot }}/{{ id }}"
{% endfor %}
