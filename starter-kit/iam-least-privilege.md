# IAM Least-Privilege Design

## Principle

Least privilege means giving an identity only the permissions it needs, on only the resources it needs, for only as long as it needs them. Nothing more, and nothing that is not strictly required for its job.

## The application task

The KijaniKiosk product service needs to read product images from an S3 bucket. It only ever fetches images; it does not add, change, or delete them.

## Why this is least privilege

- Exact action only: `s3:GetObject`, never the wildcard `s3:*`.
- Scoped resource: a single bucket (and its objects), not `*`.
- No write, delete, or list permissions are granted.
- Access is role-based, so there are no long-lived credentials to leak.

## The policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadProductImagesOnly",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::kijanikiosk-product-images/*"
    }
  ]
}
```
