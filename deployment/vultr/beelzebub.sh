#!/bin/bash
#
function retry {
  local retries=$1
  shift
  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** $count))
    count=$(($count + 1))
    if [ $count -lt $retries ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep $wait
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return $exit
    fi
  done
  return 0
}

systemctl stop --now sshd

mkdir -p /configurations/services

cat << EOT >/configurations/beelzebub.yaml
core:
  logging:
    debug: true
    debugReportCaller: false
    logDisableTimestamp: true
    logsPath: ./logs
  tracing:
    rabbitMQEnabled: true
    rabbitMQURI: "amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}"
EOT

cat << EOT >/configurations/services/ssh-2222.yaml
apiVersion: "v1"
protocol: "ssh"
address: ":2222"
description: "SSH interactive ChatGPT"
commands:
  - regex: "^(.+)$"
    plugin: "OpenAIGPTLinuxTerminal"
serverVersion: "OpenSSH"
serverName: "icd-prod-active"
passwordRegex: "^(root|admin|password|guest|123)$"
deadlineTimeoutSeconds: 60
plugin:
  openAPIChatGPTSecretKey: "${OPENAI_API_KEY}"
EOT

retry 30 docker run \
  --detach \
  --restart=always \
  --tty --interactive \
  --publish 22:2222 \
  --publish 80:8080 \
  --volume /configurations:/configurations \
    n1k06969/beelzebub:v2.0.0-custom-1678684388
    # m4r10/beelzebub:v2.0.0
