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

# db.create:
# 	mix ecto.create -r TrenurangCore.Repo

# db.reset:
# 	mix ecto.drop -r TrenurangCore.Repo && mix ecto.create -r TrenurangCore.Repo && mix ecto.migrate -r TrenurangCore.Repo

db.create:
	mix ecto.create -r TrenurangCore.Repo
	PGPASSWORD=$(DB_PASSWORD) psql -U $(DB_USERNAME) -h $(DB_HOST) -d $(DB_NAME) -c "CREATE EXTENSION IF NOT EXISTS postgis;"

db.reset:
	mix ecto.drop -r TrenurangCore.Repo && mix ecto.create -r TrenurangCore.Repo && PGPASSWORD=$(DB_PASSWORD) psql -U $(DB_USERNAME) -h $(DB_HOST) -d $(DB_NAME) -c "CREATE EXTENSION IF NOT EXISTS postgis;" && mix ecto.migrate -r TrenurangCore.Repo

db.migrate:
	mix ecto.migrate -r TrenurangCore.Repo

db.rollback:
	mix ecto.rollback -r TrenurangCore.Repo

setup:
	mix deps.get && mix ecto.create -r TrenurangCore.Repo && mix ecto.migrate -r TrenurangCore.Repo