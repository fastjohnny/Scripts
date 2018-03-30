nginx-pkg:
  pkg.installed:
    - pkgs:
      - nginx
update_name:
  file.line:
    - name: /etc/nginx/sites-enabled/default
    - mode: replace
    - content: server_name {{ pillar['server_name'] }};
    - match: server_name _;
    - require:
      - pkg: nginx-pkg
nginx-svc:
  service.running:
    - name: nginx
    - enable: True
    - require:
      - file: update_name
    - watch:
      - file: update_name
