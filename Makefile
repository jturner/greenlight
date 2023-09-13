include .envrc

SHELL = /bin/bash

## help: print this help message
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

## api/build: build the cmd/api application
api/build:
	@echo 'Building cmd/api...'
	go build -ldflags="-s" -o=./bin/api ./cmd/api
	GOOS=darwin GOARCH=amd64 go build -ldflags="-s" -o=./bin/darwin_amd64/api ./cmd/api
	GOOS=linux GOARCH=amd64 go build -ldflags="-s" -o=./bin/linux_amd64/api ./cmd/api
	GOOS=linux GOARCH=arm64 go build -ldflags="-s" -o=./bin/linux_arm64/api ./cmd/api

## api/run: run the cmd/api application
api/run:
	go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN}

## api/run/bin: run the binary cmd/api application
api/run/bin: api/build
	./bin/api -db-dsn=${GREENLIGHT_DB_DSN}

## api/clean: clean the cmd/api application build files
api/clean: confirm
	rm -rf ./bin/*

## db/psql: connect to the database using psql
db/psql:
	psql ${GREENLIGHT_DB_DSN}

## db/migrations/new name=$1: create a new database migration
db/migrations/new:
	@echo 'Creating migration files for ${name}...'
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: apply all up database migrations
db/migrations/up: confirm
	@echo 'Running up migrations...'
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up

## audit: run formatting, vetting, vuln and tests
audit: vendor
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	staticcheck ./...
	@echo 'Checking for vulns...'
	govulncheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo 'Vendoring dependencies...'
	go mod vendor

.PHONY: api/build api/clean api/run api/run/bin db/psql db/migrations/new db/migrations/up audit help confirm vendor
