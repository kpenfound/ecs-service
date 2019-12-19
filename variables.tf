variable cluster_id {}
variable name {}
variable docker_image {}
variable vpc_id {}
variable subnet_ids {}
variable task_cpu {
  default = 128
}
variable task_memory {
  default = 128
}
variable task_memory_reservation {
  default = 64
}