git_hash=$(git rev-parse HEAD)
gsed -i 's/\(.*image_tag[^=]*=[^"]*"\)[^"]*/\1'$git_hash'/g' terraform/lambda/moderately/main.tf