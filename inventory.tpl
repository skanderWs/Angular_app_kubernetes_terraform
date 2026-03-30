[master]
vm-k8s-master ansible_host=${master_ip}

[worker]
vm-k8s-worker ansible_host=${worker_ip}

[all:vars]
ansible_user=skander
ansible_ssh_private_key_file=${key_path}
ansible_python_interpreter=/usr/bin/python3