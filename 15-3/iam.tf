resource "yandex_iam_service_account" "sa" {
  name = "ig-sa"
}


resource "yandex_resourcemanager_folder_iam_member" "vpc_user" {
  folder_id = var.folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}


resource "yandex_resourcemanager_folder_iam_member" "compute_admin" {
  folder_id = var.folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam_user" {
  folder_id = var.folder_id
  role      = "iam.serviceAccounts.user"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}
