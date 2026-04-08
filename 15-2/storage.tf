resource "yandex_storage_bucket" "bucket" {
  bucket    = "student-bucket-71dzhinozfl"
  folder_id = var.folder_id
  acl       = "public-read"
}

resource "yandex_storage_object" "image" {
  bucket = yandex_storage_bucket.bucket.bucket
  key    = "71dZHINOZFL.jpg"
  source = "./71dZHINOZFL.jpg"
  acl    = "public-read"
}
