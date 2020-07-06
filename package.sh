output_directory=.glawit_deployment_package

deployment_bucket="$1"

shift

git_commit_id_core="$(
	git \
		rev-parse \
		HEAD:glawit/core \
		#
)"

git_commit_id_interface="$(
	git \
		rev-parse \
		HEAD:glawit/interface-apigw \
		#
)"

version_id="${git_commit_id_core}_${git_commit_id_interface}"

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

cd glawit

for package in core interface-apigw
do
	cd \
		"${package}" \
		#

	for python_version in "$@"
	do
		sh \
			-- \
			../interface-apigw/package.sh \
			"${python_version}" \
			"../../${output_directory}" \
			#
	done

	cd \
		.. \
		#
done

cd \
	.. \
	#

cd \
	"${output_directory}" \
	#

deployment_package_file_path="${version_id}.zip"

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

deployment_object_key="glawit/${version_id}.zip"

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
