# Data Streaming Assignment

## Setup Infrastructure

Install AWS cli

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Install jq

```bash
wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
mv jq-linux-amd64 jq
chmod +x jq
```

Install terrform according to the official installation procedure: <https://developer.hashicorp.com/terraform/install?product_intent=terraform#linux>

Install `pipenv` and other required packages

```bash
pip install pipenv
pipenv install
```

Setup AWS resources using terraform

```bash
pipenv shell
tflocal plan
tflocal apply
```

Create the IAM user for the script

```bash
awslocal iam create-user --user-name stream-user
touch ./infra/credentials.json
awslocal iam create-access-key --user-name stream-user > ./infra/credentials.json

export AWS_ACCESS_KEY_ID=$(cat infra/credentials.json | ./infra/jq '.AccessKey.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat infra/credentials.json | ./infra/jq '.AccessKey.SecretAccessKey')
```
