terraform {
  required_version = "~> 1.1.2"

  required_providers {
    aws = {
      version = "~> 4.4.0"
      source  = "hashicorp/aws"
    }
  }
}

# Download AWS provider
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Owner = "Playground Scenario 1"
      Admin = "Kyler"
    }
  }
}

resource "aws_s3_bucket" "logging-s3-buckets" {
  for_each = toset(
    [
      "cust-alpha-logging",
      "cust-beta-logging",
      "cust-theta-logging",
    ]
  )
  bucket = each.value
}

resource "aws_s3_bucket" "data-s3-buckets" {
  for_each = toset(
    [
      "cust-alpha-data",
      "cust-beta-data",
      "cust-theta-data",
    ]
  )
  bucket = each.value
}

# These users are developers
resource "aws_iam_user" "developers_iam_users" {
  for_each = toset(
    [
      "Steve",
      "Cindy",
      "Zariah",
    ]
  )
  name = each.key
}

resource "aws_iam_group" "S3-Admins" {
  name = "S3-Admins"
}

resource "aws_iam_group_policy" "S3-AdminsPolicy" {
  name  = "S3-Admins-Policy"
  group = aws_iam_group.S3-Admins.name
  # Before policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "S3Admins",
    "Statement" : [
      {
        "Sid" : "S3Admins",
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : flatten(
          concat(
            [
              for v in aws_s3_bucket.logging-s3-buckets : [
                "arn:aws:s3:::${v.bucket}",
                "arn:aws:s3:::${v.bucket}/*"
              ]
            ],
            [
              for v in aws_s3_bucket.data-s3-buckets : [
                "arn:aws:s3:::${v.bucket}",
                "arn:aws:s3:::${v.bucket}/*"
              ]
            ]
          )
        )
      }
    ]
  })
}

resource "aws_iam_group_membership" "DevelopersGroupMembership" {
  name = "Developers-Group-Membership"

  users = [
    for v in aws_iam_user.developers_iam_users : v.name
  ]

  group = aws_iam_group.S3-Admins.name
}
