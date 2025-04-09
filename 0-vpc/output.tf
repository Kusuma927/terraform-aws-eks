# output "Az_Info"{
#     value = module.vpc.az_info
# }

# output "subnets_info" {
#     value = module.vpc.subnets_info
# }
output "public_subnet_ids" {
    value = module.vpc.public_subnet_ids
}