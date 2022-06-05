#/bin/sh
git_hash=$(git rev-parse HEAD)
aws_accountid=$(aws sts get-caller-identity --query 'Account' --output text)

build_js() {
  npx tsc index.ts
}

login_to_ecr() {
  aws ecr get-login-password \
    --region eu-west-1 | docker login \
    --username AWS \
    --password-stdin $aws_accountid.dkr.ecr.eu-west-1.amazonaws.com
}

build_docker_image() {
  docker build -t moderately:$git_hash .
}

tag_docker_image() {
  docker tag moderately:$git_hash $aws_accountid.dkr.ecr.eu-west-1.amazonaws.com/api:moderately-$git_hash
}

push_docker_image() {
  docker push $aws_accountid.dkr.ecr.eu-west-1.amazonaws.com/api:moderately-$git_hash
}

build_js &&
login_to_ecr &&
build_docker_image &&
tag_docker_image &&
push_docker_image
