#!/usr/bin/env bash

# Update apt packages
set -ex
sudo yum update && sudo yum install -y wget

# Installing and configuring Gitlab Runner
sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
sudo curl --output /usr/bin/docker-credential-ecr-login https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.4.0/linux-amd64/docker-credential-ecr-login
sudo chmod +x /usr/bin/{gitlab-runner,docker-credential-ecr-login}
sudo useradd \
  --comment 'GitLab Runner' \
  --create-home \
  --shell /bin/bash \
  gitlab-runner
sudo /usr/local/bin/gitlab-runner install \
  --user="gitlab-runner" \
  --working-directory="/home/gitlab-runner"

echo -e "\nRunning scripts as '$(whoami)'\n\n"

# Configuring dockerconfig for AWS
cat > ~/dockerconfig.json <<EOF
{
	"credsStore": "ecr-login"
}
EOF
sudo mkdir -p /root/.docker
sudo mv ~/dockerconfig.json /root/.docker/config.json

# Configuring Runner PreStart, Start and Stop Scripts
cat > ~/start-gitlab-runner.sh << EOF
/usr/local/bin/gitlab-runner run            \
  --working-directory "/home/gitlab-runner" \
  --config "/etc/gitlab-runner/config.toml" \
  --service "gitlab-runner"                 \
  --user "gitlab-runner"
EOF

cat > ~/register-gitlab-runner.sh << EOF
/usr/local/bin/gitlab-runner register \
  --non-interactive \
  --env "AWS_REGION=${AWS_REGION:ap-southeast-1}" \
  --url "https://${GITLAB_URL}/" \
  --registration-token "${GITLAB_REG_TOKEN}" \
  --tag-list "docker" \
  --request-concurrency 4 \
  --executor "docker" \
  --description "Super GitLabCI Runner" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock \
  --docker-volumes "/usr/bin/docker-credential-ecr-login:/usr/bin/docker-credential-ecr-login" \
  --docker-image "docker:latest" \
  --docker-tlsverify false \
  --docker-disable-cache false \
  --docker-shm-size 0 \
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
Environment="AWS_REGION=ap-southeast-1"
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

echo -e "Making suicide script"
cat > ~/suicide.sh <<'EOF'
#!/bin/sh
logger -t "suicide" "Checking free disk space"
available_space="$(df -h | grep -w "/" | tr -s ' ' | awk '{ print $5}')"

if [ $(( 100-${available_space%%\%} )) -lt 10 ]; then
  logger -t "suicide" "Free disk space is below 10% available space, shutting down the host. Bye"
  shutdown now
fi
EOF

echo -e "Configure Suicide Service Unit File\n\n"
cat > ~/suicide.service <<'EOF'
[Unit]
Description=Runs suicide script and shutdown if free disk space below 10%
Wants=suicide.timer

[Service]
ExecStart=/bin/bash /usr/bin/suicide.sh

[Install]
WantedBy=multi-user.target
EOF

cat > ~/suicide.timer <<'EOF'
[Unit]
Description=Runs suicide script and shutdown if free disk space below 10% everyday at midnight
Requires=suicide.service

[Timer]
Unit=suicide.service
OnCalendar=*-*-* 00:00:00
AccuracySec=1s

[Install]
WantedBy=multi-user.target
EOF

chmod +x ~/suicide.sh
sudo mv ~/suicide.sh /usr/bin/
sudo mv ~/{suicide.service,suicide.timer} /etc/systemd/system/

# Service file changed - refresh systemd daemon
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl enable gitlab-runner
sudo systemctl enable suicide.timer