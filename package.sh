deployment_bucket="$1"

output_directory=.glawit_deployment_package

git_commit_id="$(
	git \
		rev-parse \
		HEAD:glawit \
		#
)"

rm \
	--force \
	--recursive \
	-- \
	"${output_directory}" \
	#

mkdir \
	-- \
	"${output_directory}" \
	#

shift

sh \
	-- \
	glawit/interface-apigw/package.sh \
	"${output_directory}" \
	"$@" \
	#

cd \
	"${output_directory}" \
	#

deployment_package_file_path="${git_commit_id}.zip"

rm \
	--force \
	--recursive \
	-- \
	"${deployment_package_file_path}" \
	#

zip \
	--recurse-paths \
	-9 \
	"${deployment_package_file_path}" \
	-- \
	python \
	#

deployment_object_key="glawit/${git_commit_id}.zip"

mime_type="$(
	file \
		--brief \
		--mime-type \
		-- \
		"${deployment_package_file_path}" \
		#
)"

aws \
	s3api \
	put-object \
	--bucket "${deployment_bucket}" \
	--key "${deployment_object_key}" \
	--body "${deployment_package_file_path}" \
	--content-type "${mime_type}" \
	#

echo "${deployment_object_key}" > object_key
