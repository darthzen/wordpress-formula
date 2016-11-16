{% from "wordpress/map.jinja" import map with context %}

include:
  - wordpress.deps
  - wordpress.cli


{% for id, site in salt['pillar.get']('wordpress:sites', {}).items() %}
{{ map.docroot }}/{{ id }}:
  file.directory:
    - user: {{ map.www_user }}
    - group: {{ map.www_group }}
    - mode: 755
    - makedirs: True

# Make sure the database exists
wordpressdb:
  mysql_database.present:
    - name: {{ site.database }}

# Make sure the database user exists
wordpressdbuser:
  mysql_user.present:
    - name: {{ site.dbuser }}
    - password: {{ site.dbpass }}
    - host: {{ site.dbhost }}
    - require:
      - wordpressdb

# Grant db permissions to user
wordpressdbgrant:
  mysql_grants.present:
    - grant: all privileges
    - database: {{ site.database }}
    - user: {{ site.dbuser }}
    - host: localhost
    - require:
      - wordpressdb
      - wordpressdbuser

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
  - name: '/usr/local/bin/wp core config --dbname="{{ site.database }}" --dbuser="{{ site.dbuser }}" --dbpass="{{ site.dbpass }}" --dbhost="{{ site.dbhost }}" --path="{{ map.docroot }}/{{ id }}"'
  - cwd: {{ map.docroot }}/{{ id }}
  - user: {{ map.www_user }}
  - unless: test -f {{ map.docroot }}/{{ id }}/wp-config.php  

# This command tells wp-cli to install wordpress
install_{{ id }}:
 cmd.run:
  - cwd: {{ map.docroot }}/{{ id }}
  - name: '/usr/local/bin/wp core install --url="{{ site.url }}" --title="{{ site.title }}" --admin_user="{{ site.username }}" --admin_password="{{ site.password }}" --admin_email="{{ site.email }}" --path="{{ map.docroot }}/{{ id }}/"'
  - user: {{ map.www_user }}
  - unless: /usr/local/bin/wp core is-installed --path="{{ map.docroot }}/{{ id }}"
{% endfor %}
