#!/bin/sh
image_uri=$(aws lambda get-function --function-name moderately | jq -r '.Code.ImageUri')
aws lambda update-function-code \
--function-name moderately \
--image-uri $image_uri \
| jq .