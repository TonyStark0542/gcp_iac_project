# gcp_iac_project

A small infrastructure-as-code project that provisions two GCP virtual machines — one Ubuntu, one CentOS — using Terraform, then configures both of them identically using Ansible, regardless of which Linux distribution they're running.

The point of this project was to practice the standard "Terraform builds it, Ansible configures it" split that most real infrastructure teams use, and to handle the fact that Ubuntu and CentOS use different package managers without writing separate playbooks for each.

## What this project covers

- Using Terraform to provision two Compute Engine VMs (Ubuntu 22.04 and CentOS Stream 9) in the same GCP project, with a shared firewall rule opening port 80 to both.
- Tagging both instances with `web-server` so the firewall rule applies to either one without needing per-instance rules.
- Injecting SSH keys into each VM through Terraform metadata, so Ansible can connect to them right after they're created with no manual setup step.
- Writing Terraform outputs for both VMs' public IPs, so they can be fed directly into an Ansible inventory without copy-pasting IPs by hand.
- Writing an Ansible playbook that detects the OS family (`ansible_facts["os_family"]`) and installs packages using `apt` for Debian-based systems or `dnf` for RedHat-based systems — same playbook, different package manager, depending on what it's talking to.
- Building a reusable Ansible role for installing and starting Nginx, instead of writing the same install/enable/start tasks inline every time.
- Writing a `lab_start.sh` helper script to handle the repetitive setup of a fresh GCP lab session — authenticating gcloud, clearing old Terraform state, generating a fresh `terraform.tfvars`, and running `terraform plan` — since these lab environments reset and need to be re-authenticated each session.

## How it fits together

```
terraform apply
      │
      ▼
┌─────────────────────┐     ┌─────────────────────┐
│   Ubuntu 22.04 VM   │     │  CentOS Stream 9 VM │
│   (tag: web-server) │     │  (tag: web-server)  │
└──────────┬──────────┘     └───────────┬─────────┘
           │                            │
           └──────────────┬─────────────┘
                           │
                  terraform output → ansible inventory
                           │
                           ▼
              ansible-playbook install_packages.yml
              ansible-playbook install_nginx_with_role.yml
                           │
              ┌────────────┴────────────┐
              ▼                          ▼
       apt install (Ubuntu)       dnf install (CentOS)
              └────────────┬────────────┘
                            ▼
                  nginx running on both
```

## Local workspace and lab automation

The lab environment I provision this on resets every session — a new GCP Project ID, new credentials, and leftover Terraform state from the day before, all of which cause real problems if they're not cleared out first. Instead of doing that setup by hand each time, `lab_start.sh` handles it.

Running `./lab_start.sh` does five things in order:

1. **Asks for the day's Project ID** and writes it into a local, git-ignored `terraform.tfvars` — so nothing needs to be edited by hand between sessions.
2. **Authenticates gcloud** and sets up Application Default Credentials, since Terraform needs those to talk to GCP.
3. **Clears out yesterday's state** — deletes the old `.terraform/` folder and `.tfstate` files so they can't interfere with today's run.
4. **Activates the Python virtual environment** if one exists, so Ansible's dependencies are ready to go.
5. **Runs `terraform init` and `terraform plan`**, so I can see what's about to be created before actually applying anything.

```
./lab_start.sh
        │
        ├── gcloud auth login + write terraform.tfvars
        ├── clear old .terraform/ and .tfstate files
        ├── activate .venv (if present)
        └── terraform init && terraform plan
```

## Folder structure

```
gcp_iac_project/
├── main.tf                          # Terraform — provisions the VMs, firewall rule, and API enablement
├── install_nginx_with_role.yml      # Ansible — current playbook, role-based
├── install_packages.yml             # Ansible — v1, direct tasks (kept for reference)
├── roles/
│   └── nginx/                       # Reusable Ansible role for web deployment
│       ├── tasks/                   # Cross-OS installation and deployment logic
│       ├── handlers/                # Idempotent Nginx restart trigger
│       ├── files/                   # Calculator web app (HTML, CSS, JS)
│       ├── vars/                    # OS-specific path mappings
│       ├── defaults/
│       ├── meta/
│       └── tests/
├── .gitignore                       # Blocks keys, state files, hosts.ini from version control
├── lab_start.sh                     # Re-authenticates and resets state for a fresh lab session
└── README.md
```

## Tech used

Terraform, Ansible, Google Compute Engine, Ubuntu, CentOS, Nginx

## Running it

```bash
# 1. Bootstrap a fresh lab session (auth + clean state + tfvars)
source lab_start.sh

# 2. Provision the infrastructure
terraform apply

# 3. Build an inventory file from the Terraform outputs, then run:
ansible-playbook -i inventory install_packages.yml
ansible-playbook -i inventory install_nginx_with_role.yml
```

## What I'd improve next

- Auto-generate the Ansible inventory file from `terraform output` instead of pasting IPs in manually.
- Move the SSH key path out of the hardcoded `~/.ssh/id_rsa.pub` and into a variable.
