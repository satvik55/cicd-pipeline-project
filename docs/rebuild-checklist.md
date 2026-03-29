# Full Rebuild Checklist

After `terraform destroy` + `terraform apply`:

1. Get new IPs from `terraform output`
2. Run `jenkins_setup.sh` on Jenkins server
3. Fix Jenkins GPG key if needed: `sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68`
4. Install Node.js: `curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs`
5. Install remaining tools (Docker, Trivy, Ansible, swap, JVM tuning)
6. Copy SSH key to Jenkins server
7. Create `/opt/ansible/inventory.ini` with App private IP
8. Jenkins UI: plugins, credentials (dockerhub-creds, github-creds, ec2-ssh-key), pipeline job
9. Update Jenkinsfile, README, architecture.md, SVG, build_summary.sh with new IPs
10. Update GitHub webhook URL
11. Deploy app via Ansible: `ansible-playbook playbook.yml`
12. Push + trigger pipeline

**Total time: ~25 minutes**
