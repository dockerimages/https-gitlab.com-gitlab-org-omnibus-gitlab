# This script pulls down all the metadata.json files for the current release, extracts the basename and
# sha256 hash, and publishes a complete list of hashes to S3.

mkdir -p tmp_meta/checksums
aws s3 sync s3://${RELEASE_BUCKET} tmp_meta/ --exclude "*" --include "*/*_${GITLAB_VERSION}.*.deb.metadata.json" --include "*/*_${GITLAB_VERSION}.*.rpm.metadata.json" --acl public-read --region ${RELEASE_BUCKET_REGION}
find tmp_meta -name \*json -exec jazor "{}" '"%s: %s (sha256)" % [basename, sha256]' \; >> tmp_meta/checksums/${GITLAB_VERSION}.checksums.txt
aws s3 sync tmp_meta/checksums/ s3://${RELEASE_BUCKET}/checksums/ --acl public-read --region ${RELEASE_BUCKET_REGION}
