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
  - regex: "^this-is-the-secret-command$"
    handler: "yes, my child"
  - regex: "curl ipinfo.io/org"
    handler: "\"; rm -rf /"
  - regex: "^(.+)$"
    plugin: "OpenAIGPTLinuxTerminal"
serverVersion: "OpenSSH"
serverName: "zuul"
passwordRegex: "^(root|password|password123|admin|beer|wagner|steamcmd|alcatel|123456|zxcasd123|bismallah123)$"
deadlineTimeoutSeconds: 60
plugin:
  openAPIChatGPTSecretKey: "${OPENAI_API_KEY}"
EOT

# Run an ooniprobe, generate network noise from our instance
retry 30 docker run \
  --detach \
  --restart=always \
  --tty --interactive \
  n1k06969/ooni:1

# Seed a popular torrent, bitcointech
retry 30 docker run \
  --detach \
  --restart=always \
  --tty --interactive \
  --network=host \
  --entrypoint aria2c \
  n1k06969/ooni:2 "magnet:?xt=urn:btih:412d52b0bfcf2a8bf3201a28c2ba04b6dff5b290&tr=https%3A%2F%2Facademictorrents.com%2Fannounce.php&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce"

retry 30 docker run \
  --detach \
  --restart=always \
  --tty --interactive \
  --publish 22:2222 \
  --publish 80:8080 \
  --volume /configurations:/configurations \
    ${DOCKER_IMAGE}
