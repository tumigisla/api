validate_git_state() {
    git diff --quiet || (>&2 echo 'Git directory dirty, exiting' && exit 1)
}

apply_terraform() {
    cd $(dirname terraform/lambda/moderately)
    >&2 terraform apply --auto-approve
}

validate_git_state &&
sh lambda/moderately/build-and-push-docker.sh &&
sh set-image-tag.sh &&
apply_terraform &&
sh lambda/moderately/restart-lambda.sh
