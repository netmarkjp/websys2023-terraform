# WEBSYS2023 Terraformサンプル

クラウドコンピューティングの講義で利用するTerraformサンプル

## 実行の前提条件

- Terraformがインストールされている
    - Terraform v1.4.6、 provider.aws v5.2.0 でテスト済み
    - https://learn.hashicorp.com/tutorials/terraform/install-cli

## 実行方法

```sh
terraform init
terraform plan
terraform apply

# 終わったら
terraform destroy
```
