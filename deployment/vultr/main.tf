
resource "vultr_startup_script" "beelzebub" {
    name = "beelzebub"
    script = base64encode(templatefile("${path.module}/beelzebub.sh", {
        RABBITMQ_USER = var.rabbitmq_user,
        RABBITMQ_PASS = var.rabbitmq_pass,
        RABBITMQ_HOST = var.rabbitmq_host,
        OPENAI_API_KEY = var.openai_api_key,
        DOCKER_IMAGE = var.docker_image,
    }))
}

resource "vultr_instance" "beelzebub" {
    plan = "vc2-1c-1gb"
    region = "lax"
    // os_id = 424
    app_id = 17
    // snapshot_id = var.snapshot_id // too slow on vultr
    label = "beelzebub"
    tags = ["honeypot"]
    hostname = "beelzebub"
    script_id = vultr_startup_script.beelzebub.id
}

output "beelzebub_ip" {
    value = vultr_instance.beelzebub.main_ip
}

output "beelzebub_id" {
    value = vultr_instance.beelzebub.id
}
