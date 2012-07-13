#update phpbb_config set config_value = 'db' where config_name = 'auth_method';
#update phpbb_config set config_value = 'ldap' where config_name = 'auth_method';
update phpbb_config set config_value = '%auth-method%' where config_name = 'auth_method';

update phpbb_config set config_value = 'ldap://%ldap-server%' where config_name = 'ldap_server';
update phpbb_config set config_value = '%ldap-username%' where config_name = 'ldap_user';
update phpbb_config set config_value = '%ldap-password%' where config_name = 'ldap_password';
update phpbb_config set config_value = 'mail' where config_name = 'ldap_email';
update phpbb_config set config_value = 'ou=users,dc=netsoc,dc=dit,dc=ie' where config_name = 'ldap_base_dn';
update phpbb_config set config_value = 'forum.netsoc.dit.ie' where config_name = 'server_name';
update phpbb_config set config_value = '443' where config_name = 'server_port';
update phpbb_config set config_value = 'https://' where config_name = 'server_protocol';

