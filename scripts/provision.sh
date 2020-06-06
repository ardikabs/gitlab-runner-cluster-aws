#!/usr/bin/env bash

# Update apt packages
set -ex
sudo yum update && sudo yum install -y wget

# Installing and configuring Gitlab Runner
sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
sudo chmod +x /usr/local/bin/gitlab-runner
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
sudo /usr/local/bin/gitlab-runner install --user="gitlab-runner" --working-directory="/home/gitlab-runner"
echo -e "\nRunning scripts as '$(whoami)'\n\n"

# Configuring Runner PreStart, Start and Stop Scripts
cat > ~/start-gitlab-runner.sh << EOF
/usr/local/bin/gitlab-runner run            \
  --working-directory "/home/gitlab-runner" \
  --config "/etc/gitlab-runner/config.toml" \
  --service "gitlab-runner"                 \
  --user "gitlab-runner"
EOF
cat > ~/register-gitlab-runner.sh << EOF
/usr/local/bin/gitlab-runner register                          \
  --non-interactive                                            \
  --url "https://${GITLAB_URL}/"                               \
  --registration-token "${GITLAB_REG_TOKEN}"                   \
  --tag-list "docker"                                          \
  --request-concurrency 4                                      \
  --executor "docker"                                          \
  --description "Some Runner Description"                      \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-image "docker:latest"                               \
  --docker-tlsverify false                                     \
  --docker-disable-cache false                                 \
  --docker-shm-size 0                                          \
  --locked="true"
EOF

cat > ~/deregister-gitlab-runner.sh << EOF
/usr/local/bin/gitlab-runner "unregister" "--all-runners"
EOF

echo -e "\nMaking scripts executable"
chmod +x ~/{start,register,deregister}-gitlab-runner.sh

# Move scripts to /usr/bin/
sudo mv ~/{start,register,deregister}-gitlab-runner.sh /usr/bin/
echo -e "\nConfigure Gitlab Runner Service Unit File"

cat > ~/gitlab-runner.service << EOF
[Unit]
Description=GitLab Runner
After=syslog.target network.target
ConditionFileIsExecutable=/usr/local/bin/gitlab-runner
[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/bin/bash /usr/bin/start-gitlab-runner.sh
ExecStartPost=/bin/bash /usr/bin/register-gitlab-runner.sh
ExecStop=/bin/bash /usr/bin/deregister-gitlab-runner.sh
Restart=always
RestartSec=120
[Install]
WantedBy=multi-user.target
EOF

# Move SystemD service unit file to /etc/systemd/system
sudo mv ~/gitlab-runner.service /etc/systemd/system/
sudo systemctl enable gitlab-runner

# Service file changed - refresh systemd daemon
sudo systemctl daemon-reload