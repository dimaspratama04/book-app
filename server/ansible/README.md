# Ansible — Docker + K3s Provisioning

Infrastructure-as-Code to provision a server (Debian/Ubuntu) with:

1. **Docker Engine** — installed from Docker's official apt repository.
2. **K3s** — a lightweight, single-node Kubernetes distribution.

## Structure

```
ansible/
├── ansible.cfg            # Ansible configuration (inventory path, roles path, sudo)
├── site.yml               # Main playbook: runs the docker + k3s roles
├── inventory/
│   └── hosts.ini          # Target hosts inventory
└── roles/
    ├── docker/            # Installs Docker Engine + compose plugin
    │   ├── defaults/main.yml
    │   ├── handlers/main.yml
    │   └── tasks/main.yml
    └── k3s/               # Installs K3s via the official install script
        ├── defaults/main.yml
        ├── handlers/main.yml
        └── tasks/main.yml
```

## Requirements

- Ansible 2.12+ on your control machine.
- Target host(s) running Debian or Ubuntu with SSH access and sudo privileges.
- Python 3 on the target host(s).

## Configure the inventory

Edit `inventory/hosts.ini` and add your server under `[k3s_servers]`:

```ini
[k3s_servers]
server1 ansible_host=192.168.1.10 ansible_user=ubuntu
```

## Run

Provision a remote server:

```bash
cd server/ansible
ansible-playbook site.yml --limit k3s_servers
```

Run against the local machine (control node itself):

```bash
ansible-playbook site.yml --limit local
```

Dry run (check mode) to preview changes:

```bash
ansible-playbook site.yml --limit k3s_servers --check
```

## Common variables

Override these with `-e` or in your inventory/group vars.

| Variable           | Default                          | Description                                   |
| ------------------ | -------------------------------- | --------------------------------------------- |
| `docker_users`     | the connecting user              | Users added to the `docker` group             |
| `k3s_version`      | `""` (latest stable)             | Pin a specific K3s version, e.g. `v1.30.2+k3s1` |
| `k3s_server_args`  | `--write-kubeconfig-mode 644`    | Extra args for the K3s server install         |

Example — pin a K3s version:

```bash
ansible-playbook site.yml --limit k3s_servers -e k3s_version=v1.30.2+k3s1
```

## Verify

After the playbook completes, on the target host:

```bash
docker --version
sudo k3s kubectl get nodes
```

The kubeconfig is written to `/etc/rancher/k3s/k3s.yaml`.
