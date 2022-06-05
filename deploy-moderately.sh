validate_git_state() {
    git diff --quiet || (>&2 echo 'Git directory dirty, exiting' && exit 1)
}

build_and_push_docker() {
    pushd lambda/moderately
    >&2 sh build-and-push-docker.sh    
    popd
}

apply_terraform() {
    pushd terraform/lambda/moderately
    >&2 terraform apply --auto-approve
    popd
}

restart_lambda() {
    pushd lambda/moderately
    >&2 sh restart-lambda.sh
    popd
}


validate_git_state &&
build_and_push_docker &&
sh set-image-tag.sh &&
apply_terraform &&
restart_lambda &&
git commit -am "updated image tag"
