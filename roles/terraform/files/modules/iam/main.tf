resource "aws_iam_group" "engenheiro_lake" {
  name = "engineer"
  path = "/users/"
}

resource "aws_iam_role" "engenheiro_role" {
  name = "engenheiro-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect    = "Allow",
        Sid       = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "engenheiro_policy" {
  name  = "engenheiro-policy"
  role = aws_iam_role.engenheiro_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:*",
          "glue:*",
          "athena:*",
          "emr:*",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_group" "adm_lake" {
  name = "admin"
  path = "/users/"
}

resource "aws_iam_group_policy" "adm_policy" {
  name  = "adm-policy"
  group = aws_iam_group.adm_lake.name
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["*"],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_group" "usuario_lake" {
  name = "user"
  path = "/users/"
}

resource "aws_iam_group_policy" "usuario_policy" {
  name  = "usuario-policy"
  group = aws_iam_group.usuario_lake.name
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role" "emr_servico_role" {
  name = "role-servico-emr"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Action" = "sts:AssumeRole"
        "Effect" = "Allow"
        "Principal" = {
          "Service" = "elasticmapreduce.amazonaws.com"
        }
      }
    ]
  })
}

variable "emr_servico_policies" {
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole",
    "arn:aws:iam::aws:policy/AmazonMSKReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "emr_servico_policy_attachments" {
  for_each = toset(var.emr_servico_policies)  
  role = aws_iam_role.emr_servico_role.name
  policy_arn = each.key 
}

resource "aws_iam_role" "emr_ec2_role" {
  name = "role-ec2-emr"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17"
    "Statement": [{
      "Effect": "Allow"
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
      "Action": "sts:AssumeRole"
    }]
  })
}

variable "emr_ec2_policies" {
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonMSKReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]
}

resource "aws_iam_role_policy_attachment" "emr_ec2_policy_attachments" {
  for_each = toset(var.emr_ec2_policies)  
  role = aws_iam_role.emr_ec2_role.name
  policy_arn = each.key 
}

resource "aws_iam_instance_profile" "emr_instance_profile" {
  name = "emr-ec2_instance-profile"
  role = aws_iam_role.emr_ec2_role.name
}

resource "aws_iam_policy" "msk_ec2_policy" {
  name = "msk-ec2-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:*Topic*",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DeleteGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "msk_ec2_role" {
  name = "msk-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "msk_ec2_policy_attachment" {
  role = aws_iam_role.msk_ec2_role.name
  policy_arn = aws_iam_policy.msk_ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "emr_ec2_msk_policy_attachment" {
  role = aws_iam_role.emr_ec2_role.name
  policy_arn = aws_iam_policy.msk_ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "emr_service_msk_policy_attachment" {
  role = aws_iam_role.emr_servico_role.name
  policy_arn = aws_iam_policy.msk_ec2_policy.arn
}

resource "aws_iam_instance_profile" "msk_instance_profile" {
  name = "msk-instance-profile"
  role = aws_iam_role.msk_ec2_role.name
}

output "engenheiro_servico_role" {
  value = aws_iam_role.engenheiro_role.arn
}

output "emr_instance_profile_arn" {
  value = aws_iam_instance_profile.emr_instance_profile.arn
}

output "emr_servico_role" {
  value = aws_iam_role.emr_servico_role.arn
}

output "msk_instance_profile_name" {
  value = aws_iam_instance_profile.msk_instance_profile.name
}