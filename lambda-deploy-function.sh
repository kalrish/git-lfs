deployment_bucket="${1}"
source_directory="${2}"
http_method="${3}"

cd "${source_directory}"

function_source_file_path="${http_method}.py"

checksum="$(sha256sum -- "${function_source_file_path}")"
checksum="${checksum%% *}"

deployment_package_file_path="${http_method}.zip"

zip -q -9 "${deployment_package_file_path}" -- "${function_source_file_path}"

deployment_object_key="lambda/git-lfs/function/${checksum}.zip"

aws s3api put-object --bucket "${deployment_bucket}" --key "${deployment_object_key}" --body "${deployment_package_file_path}"

echo "${deployment_object_key}" > "${http_method}.txt"
