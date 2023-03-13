
resource "vultr_startup_script" "beelzebub" {
  name = "beelzebub"
  script = base64encode(templatefile("${path.module}/beelzebub.sh", {
    RABBITMQ_USER  = var.rabbitmq_user,
    RABBITMQ_PASS  = var.rabbitmq_pass,
    RABBITMQ_HOST  = var.rabbitmq_host,
    OPENAI_API_KEY = var.openai_api_key,
    DOCKER_IMAGE   = var.docker_image,
  }))
}

resource "vultr_instance" "beelzebub" {
  for_each  = { for node in var.nodes : node.region => node }
  region    = try(each.value.region, "lax")
  plan      = "vc2-1c-1gb"
  app_id    = 17
  label     = "beelzebub"
  tags      = ["honeypot", each.value.region]
  hostname  = format("%s-beelzebub", each.value.region)
  script_id = vultr_startup_script.beelzebub.id
}

output "beelzebub_ip" {
  value = values(vultr_instance.beelzebub).*.main_ip
}
