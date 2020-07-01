deployment_bucket="$1"

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
	glawit_deployment_package \
	glawit_deployment_package.zip \
	#

mkdir \
	-- \
	glawit_deployment_package \
	#

shift

for python_version in "$@"
do
	container_id="$(
		docker \
			run \
			--interactive \
			--tty \
			--detach \
			--volume "${PWD}/glawit:/var/task:ro" \
			-- \
			"lambci/lambda:build-python${python_version}" \
			/bin/sh \
			#
	)"

	for package in core interface_apigw
	do
		docker \
			exec \
			--workdir /var/task \
			-- \
			"${container_id}" \
			pip \
			wheel \
			--no-deps \
			--build /tmp/build \
			--wheel-dir /tmp/whl \
			--progress-bar off \
			-- \
			"./${package}" \
			#
	done

	docker \
		exec \
		-- \
		"${container_id}" \
		sh \
		-c \
		"pip install --target /tmp/deployment_package/python/lib/python${python_version}/site-packages/ /tmp/whl/*" \
		#

	docker \
		cp \
		-- \
		"${container_id}:/tmp/deployment_package/." \
		glawit_deployment_package \
		#

	docker \
		container \
		stop \
		-- \
		"${container_id}"

	docker \
		rm \
		-- \
		"${container_id}"
done

cd \
	glawit_deployment_package \
	#

deployment_package_file_path="${git_commit_id}.zip"

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
	--content-type application/zip \
	#

echo "${deployment_object_key}" > object_key
