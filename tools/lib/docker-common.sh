#!/usr/bin/env bash

ensure_docker() {
	if ! command -v docker >/dev/null 2>&1; then
		echo "Docker is not installed. Install Docker Desktop first." >&2
		exit 1
	fi

	if ! docker info >/dev/null 2>&1; then
		echo "Docker daemon is not running. Start Docker Desktop and try again." >&2
		exit 1
	fi
}
