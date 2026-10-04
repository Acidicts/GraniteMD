# README

A web app inspired by obsidian md, but designed on the web.
Running on Rails 8.1.4 with ruby 4.0.7

## System dependencies
- libvips
- ruby
- All the gems in [gemfile](/Gemfile) installed with `bundle install`
- Postgres DB
- Redis DB (for caching)

## Configuration
1. Copy `.env.example` into a `.env`
2. Fill out the variables

## Database creation
`. After cloning the project open a terminal in the project and run `bin/rails db:create`
2. After creating it run `bin/rails db:migrate`

## To run a test suite
You need rspec Gem to be installed, then you can run `bundle exec rspec`

## Services
This uses databases, and email smtp to run

## Deployment instructions
~ Needs [Docker](https://www.docker.com/) for easy run
1. Run `docker pull ghcr.io/acidicts/issued:latest`
	If github needs authentication do:
	```
	echo "$GITHUB_TOKEN" | docker login ghcr.io -u Acidicts --password-stdin
	docker pull ghcr.io/acidicts/issued:latest
	```
2. Download [.env.example](/.env.example)
3. Rename `.env.example` to `.env`
4. Create a docker compose file eg:
	docker-compose.yml:
	```
	services:
	  web:
	    image: ghcr.io/acidicts/issued:latest
	    env_file:
	      - .env
	    environment:
	      RAILS_ENV: production
	      RACK_ENV: production
	      DB_HOST: db
	      DB_PORT: 5432
	      DB_USERNAME: postgres
	      DB_PASSWORD: postgres
	      REDIS_URL: redis://redis:6379/0
	      PORT: 3000
	    ports:
	      - "3000:3000"
	    depends_on:
	      db:
	        condition: service_healthy
	      redis:
	        condition: service_started
	    restart: unless-stopped
	
	  db:
	    image: postgres:17
	    environment:
	      POSTGRES_USER: postgres
	      POSTGRES_PASSWORD: postgres
	      POSTGRES_DB: issued_production
	    volumes:
	      - postgres_data:/var/lib/postgresql/data
	    healthcheck:
	      test: ["CMD-SHELL", "pg_isready -U postgres -d issued_production"]
	      interval: 5s
	      timeout: 5s
	      retries: 10
	
	  redis:
	    image: redis:7-alpine
	    volumes:
	      - redis_data:/data
	
	volumes:
	  postgres_data:
	  redis_data:
	```
4. Start the application with `docker compose up -d`

Alternatively if you already have a postgres and redis instance you can do:
```
docker run --rm \
  --name issued \
  --env-file .env \
  -e DB_HOST=your-postgres-host \
  -e DB_PORT=5432 \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=your-password \
  -e REDIS_URL=redis://your-redis-host:6379/0 \
  -p 3000:3000 \
  ghcr.io/acidicts/issued:latest
```

### Credits
- RSpec Shard code and .github/actions/setup-[db/ruby] in ci.yml from [hackclub/hcb](https://github.com/hackclub/hcb)
