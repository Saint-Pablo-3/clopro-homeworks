# output "lb_external_ip" {
#   value = [
#     for l in yandex_lb_network_load_balancer.nlb.listener :
#     [
#       for addr in l.external_address_spec :
#       addr.address
#     ][0]
#   ][0]
# }
