output "pub_subnet_1_id" {
  value = aws_subnet.public_subnets[0].id
}
output "pub_subnet_2_id" {
  value = aws_subnet.public_subnets[1].id
}
output "pub_subnet_3_id" {
  value = aws_subnet.public_subnets[2].id
}


output "pri_subnet_1_id" {
  value = aws_subnet.private_subnets[0].id
}
output "pri_subnet_2_id" {
  value = aws_subnet.private_subnets[1].id
}
output "pri_subnet_3_id" {
  value = aws_subnet.private_subnets[2].id
}
