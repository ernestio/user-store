#!/usr/bin/env sh

echo "Waiting for Postgres"
while ! echo exit | nc postgres 5432; do sleep 10; done

echo "Starting user-store"
/go/bin/user-store
