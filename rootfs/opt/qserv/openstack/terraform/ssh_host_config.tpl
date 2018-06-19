Host %s
HostName %s
User qserv
Port 22
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
PasswordAuthentication no
ProxyCommand ssh -i ${key_filename} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %%h:%%p qserv@${floating_ip}
IdentityFile ${key_filename}
IdentitiesOnly yes
LogLevel FATAL
