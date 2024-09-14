resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.account_id}-tf-state"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "${var.account_id}-tf-locks"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
