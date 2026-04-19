include .env
export

dev:
	mix phx.server

run:
	mix run --no-halt

test:
	mix test

test.watch:
	mix test.watch

db.create:
	mix ecto.create

db.migrate:
	mix ecto.migrate

db.reset:
	mix ecto.drop && mix ecto.create && mix ecto.migrate

db.rollback:
	mix ecto.rollback

setup:
	mix deps.get && mix ecto.create && mix ecto.migrate