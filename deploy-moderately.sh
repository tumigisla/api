validate_git_state() {
    git diff --quiet || (>&2 echo 'Git directory dirty, exiting' && exit 1)
}

build_and_push_docker() {
    pushd lambda/moderately
    >&2 sh lambda/moderately/build-and-push-docker.sh    
    popd
}

apply_terraform() {
    pushd terraform/lambda/moderately
    >&2 terraform apply --auto-approve
    popd
}


validate_git_state &&
build_and_push_docker &&
sh set-image-tag.sh &&
apply_terraform &&
sh lambda/moderately/restart-lambda.sh
