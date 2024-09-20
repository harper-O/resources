{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SNSAccess",
            "Effect": "Allow",
            "Action": [
                "sns:*"
            ],
            "Resource": [
                "arn:aws:sns:*:*:*payportal*",
                "arn:aws:sns:*:*:*sds*",
                "arn:aws:sns:*:*:*fanflare*",
                "arn:aws:sns:*:*:*hoc*"
            ]
        },
        {
            "Sid": "S3Access",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::*payportal*",
                "arn:aws:s3:::*sds*",
                "arn:aws:s3:::*fanflare*",
                "arn:aws:s3:::*hoc*",
                "arn:aws:s3:::*payportal*/*",
                "arn:aws:s3:::*sds*/*",
                "arn:aws:s3:::*fanflare*/*",
                "arn:aws:s3:::*hoc*/*"
            ]
        },
        {
            "Sid": "LambdaAccess",
            "Effect": "Allow",
            "Action": [
                "lambda:*"
            ],
            "Resource": [
                "arn:aws:lambda:*:*:function:*payportal*",
                "arn:aws:lambda:*:*:function:*sds*",
                "arn:aws:lambda:*:*:function:*fanflare*",
                "arn:aws:lambda:*:*:function:*hoc*"
            ]
        },
        {
            "Sid": "CloudFrontAccess",
            "Effect": "Allow",
            "Action": [
                "cloudfront:*"
            ],
            "Resource": [
                "arn:aws:cloudfront::*:distribution/*"
            ],
            "Condition": {
                "StringLike": {
                    "cloudfront:comment": [
                        "*payportal*",
                        "*sds*",
                        "*fanflare*",
                        "*hoc*"
                    ]
                }
            }
        },
        {
            "Sid": "SESAccess",
            "Effect": "Allow",
            "Action": [
                "ses:*"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ses:identity": [
                        "*payportal*",
                        "*sds*",
                        "*fanflare*",
                        "*hoc*"
                    ]
                }
            }
        }
    ]
}
