# Ansible Role: nginx

Deploys a custom web application across Ubuntu and CentOS nodes using a single unified role. Handles OS-specific package installation, web root management, asset deployment, and service restarts — all without duplicating logic per distribution.

---

## Role Structure

```
roles/nginx/
├── tasks/
│   └── main.yml       # OS-conditional install + deploy task sequence
├── handlers/
│   └── main.yml       # Nginx restart — fires only when files change
├── files/
│   ├── index.html     # Calculator app — markup
│   ├── style.css      # Calculator app — layout and styling
│   └── script.js      # Calculator app — interactive logic
├── vars/
│   └── main.yml       # OS-specific web root path mapping
├── defaults/
│   └── main.yml       # Role-level defaults
├── meta/
│   └── main.yml       # Role metadata
└── tests/
```

---

## How the OS Detection Works

Both target VMs run different Linux distributions with different package managers and different default web root paths. Rather than writing separate roles or playbooks per OS, this role queries the `ansible_facts['os_family']` value at runtime and branches accordingly.

**Package Installation:**
- Ubuntu host (`os_family: Debian`) → `ansible.builtin.apt` installs `nginx`
- CentOS host (`os_family: RedHat`) → `ansible.builtin.dnf` installs `nginx`

Each task has a `when:` condition so it only runs on its target family. The other host skips it cleanly — visible in the playbook output as `skipping`.

**Web Root Paths (set in `vars/main.yml`):**
- Ubuntu → `/var/www/html`
- CentOS → `/usr/share/nginx/html`

The `web_root` variable is set dynamically based on OS family so subsequent tasks — purge, deploy — don't need to hardcode any paths.

---

## Task Execution Sequence

**1. Install Nginx** — conditional on OS family, routes to the correct package module.

**2. Purge default web server files** — clears everything inside `web_root` before deploying. This prevents vendor welcome pages from bleeding through and guarantees a clean deployment state on every run.

**3. Deploy frontend assets** — copies `index.html`, `style.css`, and `script.js` from the role's `files/` directory to the correct `web_root` on each host. Runs on both nodes simultaneously.

**4. Restart Nginx (handler)** — fires automatically if and only if the file deployment task registers a change. If files are identical on a re-run, the handler stays silent. No unnecessary downtime.

---

## The Handler Behavior

This is worth understanding clearly because it's one of those things people get wrong.

The deploy task notifies the handler named `Restart Nginx`. The handler doesn't run immediately when notified — it queues and runs at the end of the play, after all tasks complete. And critically, if the deploy task reports `ok` instead of `changed` (meaning files were already in sync), the notification never fires and the handler never runs.

This makes the role safe to re-run repeatedly without side effects.

---

## What Gets Deployed

A responsive calculator web application with full arithmetic operations. The app is served directly by Nginx over HTTP on port 80. It was confirmed live on the CentOS VM (`136.114.248.234`) and the Ubuntu VM (`35.254.145.10`) after a single playbook run.

The point of the app itself isn't the calculator — it's proving that a complete multi-file frontend (HTML + CSS + JS) can be deployed atomically to heterogeneous infrastructure with zero manual steps.
