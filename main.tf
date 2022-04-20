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

resource "aws_iam_group" "S3-PowerUsers" {
  name = "S3-PowerUsers"
}

resource "aws_iam_group_policy" "S3-PowerUsers" {
  name  = "S3-PowerUsers-Policy"
  group = aws_iam_group.S3-PowerUsers.name
  # Before policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "S3PowerUsers",
    "Statement" : [
      {
        "Sid" : "S3PowerUsers",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketAnalyticsConfiguration",
          "s3:GetBucketCors",
          "s3:GetBucketEncryption",
          "s3:GetBucketIntelligentTieringConfiguration",
          "s3:GetBucketInventoryConfiguration",
          "s3:GetBucketLifecycle",
          "s3:GetBucketLifecycleConfiguration",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketMetricsConfiguration",
          "s3:GetBucketNotification",
          "s3:GetBucketNotificationConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketPolicy",
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketReplication",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectAttributes",
          "s3:GetObjectLegalHold",
          "s3:GetObjectLockConfiguration",
          "s3:GetObjectRetention",
          "s3:GetObjectTagging",
          "s3:GetObjectTorrent",
          "s3:GetPublicAccessBlock",
          "s3:ListBucketAnalyticsConfigurations",
          "s3:ListBucketIntelligentTieringConfigurations",
          "s3:ListBucketInventoryConfigurations",
          "s3:ListBucketMetricsConfigurations",
          "s3:ListBuckets",
          "s3:ListMultipartUploads",
          "s3:ListObjects",
          "s3:ListObjectsV2",
          "s3:ListObjectVersions",
          "s3:ListParts"
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

  group = aws_iam_group.S3-PowerUsers.name
}