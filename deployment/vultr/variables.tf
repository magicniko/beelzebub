variable "rabbitmq_user" {
  type = string
}

variable "rabbitmq_pass" {
  type = string
}

variable "rabbitmq_host" {
  type = string
}

variable "openai_api_key" {
  type = string
}

variable "snapshot_id" {
  type = string
}

variable "docker_image" {
  type = string
}

variable "nodes" {
  type = list(object(
    {
      region = string
      name = string
    }
  ))
}