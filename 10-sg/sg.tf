module "mysql_sg" {
     source = "../../terraform-aws-securitygroup"
    #source="git::https://github.com/DAWS-82S/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "mysql"
    sg_description = "Created for MySQL instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "bastion_sg" {
    source = "../../terraform-aws-securitygroup"
    #source="git::https://github.com/DAWS-82S/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "bastion"
    sg_description = "Created for bastion instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "alb_ingress_sg" {
    source = "../../terraform-aws-securitygroup"
    #source="git::https://github.com/DAWS-82S/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "app_alb"
    sg_description = "Created for backend ALB in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "eks_controlplane_sg" {
    source = "../../terraform-aws-securitygroup"
    #source="git::https://github.com/DAWS-82S/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "eks-controlplane"
    sg_description = "Created for backend ALB in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "eks_node_sg" {
    source = "../../terraform-aws-securitygroup"
    #source="git::https://github.com/DAWS-82S/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "eks-node"
    sg_description = "Created for backend ALB in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

##VPN SG 
##Port# (22 - To Login into servers), (443 - To establish connection to browser), (1194,943 - are for Admin roles)
module "vpn_sg" {
    source = "../../terraform-aws-securitygroup"
    #source="git::https://github.com/DAWS-82S/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "vpn"
    sg_description = "Created for VPN Instance in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

#Traffic flowing from NODE to Control plane 
resource "aws_security_group_rule" "eks_control_plane_node" {
    type = "ingress"
    from_port = 0
    to_port =0
    protocol = "-1"
    source_security_group_id       = module.eks_node_sg.sg_id //We are mapping source_security ID of Bastion to this SG.
    security_group_id = module.eks_controlplane_sg.sg_id  
}

#NODE accepting traffic from Control plane OR Traffic flowing from Control plane to NODE
resource "aws_security_group_rule" "eks_node_eks_control_plane_node" {
    type = "ingress"
    from_port = 0
    to_port =0
    protocol = "-1"
    source_security_group_id       = module.alb_ingress_sg.sg_id //We are mapping source_security ID of Bastion to this SG.
    security_group_id = module.eks_node_sg.sg_id  
}

resource "aws_security_group_rule" "node_alb_ingress" {
    type = "ingress"
    from_port = 30000
    to_port =32767
    protocol = "tcp"
    source_security_group_id       = module.alb_ingress_sg.sg_id //We are mapping source_security ID of Bastion to this SG.
    security_group_id = module.eks_node_sg.sg_id  
}

## Node is accepting traffic from our VPC
resource "aws_security_group_rule" "node_vpc" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]   ## Our private IP address range 
    security_group_id = module.eks_node_sg.sg_id  
}

## Node is accepting traffic from our Bastion Host
resource "aws_security_group_rule" "node_bastion" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id       = module.bastion_sg.sg_id 
    security_group_id = module.eks_node_sg.sg_id  
}

#App ALB Accepting traffic from Bastion Host
resource "aws_security_group_rule" "alb_ingress_bastion" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id       = module.bastion_sg.sg_id //We are mapping source_security ID of Bastion to this SG.
    security_group_id = module.alb_ingress_sg.sg_id  
}

#App ALB Accepting traffic from Bastion Host
resource "aws_security_group_rule" "alb_ingress_bastion_https" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    source_security_group_id       = module.bastion_sg.sg_id //We are mapping source_security ID of Bastion to this SG.
    security_group_id = module.alb_ingress_sg.sg_id  
}   

#App ALB Accepting traffic from Public
resource "aws_security_group_rule" "alb_ingress_public_https" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    security_group_id = module.alb_ingress_sg.sg_id  
} 

## Creating bastion SG Rule
resource "aws_security_group_rule" "bastion_public" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]## Usually it should be static IP, since it cost.. we are using the default one.
    security_group_id = module.bastion_sg.sg_id  
}

## Receiving traffic from bastion to connect to sql server
resource "aws_security_group_rule" "mysql_bastion" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = module.bastion_sg.sg_id
    security_group_id = module.mysql_sg.sg_id  
}


## ACcepting traffic from eks node to sql server
resource "aws_security_group_rule" "mysql_eks_node" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = module.eks_node.sg_id
    security_group_id = module.mysql_sg.sg_id  
}


