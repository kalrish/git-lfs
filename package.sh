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

zip \
	--recurse-paths \
	-9 \
	../glawit_deployment_package.zip \
	-- \
	python \
	#
