#!/usr/bin/env bats

load '../.bats/bats-support/load'
load '../.bats/bats-assert/load'
load '../.bats/bats-file/load'

# root directory for the test cases
export BASE_DIR=""

function setup() {
	# creating a temporary directory before each test run below
	BASE_DIR="$(mktemp -d ${BATS_TMPDIR}/bats.XXXXXX)"

	chmod -R 777 ${BASE_DIR} >/dev/null

	# making sure the tests will "fail fast", when a given test fails the suite stops
	[ -n "${BATS_TEST_COMPLETED}" ] || touch ${BATS_PARENT_TMPNAME}.skip
}

function teardown() {
	rm -rfv ${BASE_DIR} || true
}