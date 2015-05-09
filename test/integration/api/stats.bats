#!/usr/bin/env bats

load ../helpers

function teardown() {
	swarm_manage_cleanup
	stop_docker
}

@test "docker stats" {
	TEMP_FILE=$(mktemp)
	start_docker_with_busybox 2
	swarm_manage

	# stats running container 
	docker_swarm run -d --name test_container busybox sleep 50

	# make sure container is up
	# FIXME(#748): Retry required because of race condition.
	retry 5 0.5 eval "[ $(docker_swarm inspect -f '{{ .State.Running }}' test_container) == 'true' ]"

	# storage the stats output in TEMP_FILE
	# it will stop automatically when manager stop
	docker_swarm stats test_container > $TEMP_FILE &

	# retry until TEMP_FILE is not empty
	retry 5 1 eval "[ -s $TEMP_FILE ]"

	# verify content
	grep -q "CPU %" "$TEMP_FILE"
	grep -q "MEM USAGE/LIMIT" "$TEMP_FILE"

	rm -f $TEMP_FILE
}
