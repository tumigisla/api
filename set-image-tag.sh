git_hash=$(git rev-parse HEAD)
sed -i 's/\(.*image_tag[^=]*=[^"]*"\)[^"]*/\1'$git_hash'/g' ./terraform/lambda/moderately/main.tf