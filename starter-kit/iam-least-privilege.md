# IAM Least-Privilege Design

## Principle

<!-- 1-2 sentences: define least privilege in your own words. -->

## The application task

<!-- 1-2 sentences: describe ONE clear task. Example: "The KijaniKiosk product
     service needs to read product images from an S3 bucket." -->

## Why this is least privilege

<!-- 2-3 bullets: exact action only (s3:GetObject, not s3:*), scoped resource
     (one bucket / one prefix, not *), no delete/write permissions,
     role-based (no long-lived keys). -->

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

<!-- Adjust the bucket name/resource above to match YOUR described task.
     If your task is different, change the Action and Resource accordingly. -->
