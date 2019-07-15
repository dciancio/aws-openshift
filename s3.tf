resource "aws_s3_bucket" "registry" {
  count  = var.use_s3_registry ? 1 : 0
  bucket = "${local.s3bucketname}"
  acl    = "private"
  tags = {
    Name = "${local.s3bucketname}"
  }
}

resource "aws_s3_bucket_public_access_block" "registry" {
  count  = var.use_s3_registry ? 1 : 0
  bucket = "${aws_s3_bucket.registry[count.index].id}"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

