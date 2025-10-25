[all:vars]
ansible_user=dudin
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[bastion]
${bastion_fqdn} ansible_host=${bastion_ip}

[web_servers]
${web1_fqdn} ansible_host=${web1_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q dudin@${bastion_ip}"'
${web2_fqdn} ansible_host=${web2_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q dudin@${bastion_ip}"'

[monitoring]
${zabbix_fqdn} ansible_host=${zabbix_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q dudin@${bastion_ip}"'

[elk]
${elasticsearch_fqdn} ansible_host=${elasticsearch_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q dudin@${bastion_ip}"'

[kibana]
${kibana_fqdn} ansible_host=${kibana_ip} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q dudin@${bastion_ip}"'

