ENTRYPOINT := ./entrypoint.sh
PORT := 5000


## Invoke Application
.PHONY: development production
development:	## run application in development mode
	@FLASK_ENV=$@ $(ENTRYPOINT) --debug

production:		## run application in production
	@FLASK_ENV=$@ FLASK_PORT=$(PORT) $(ENTRYPOINT)


## Data Management
.PHONY: db/migrations
db/migrations: 	## update migrations/versions/ dir latest migration versions.py
	@flask --env-file .env db migrate -m "Latest db updates for PR; created: $(date --utc +%Y%m%d_%H%M%SZ)"


## Application automation
IMAGE := example
VERSION = latest
REGISTRY = ghcr.io/michaelquong

.PHONY: image image/tag container
image:		## build application image
	@docker build -t my/$(IMAGE):latest .

image/tag:	## tag and push latest image
	@docker tag my/$(IMAGE):latest $(REGISTRY)/$(IMAGE):$(VERSION)
	@docker push $(REGISTRY)/$(IMAGE):$(VERSION)

.data:	## create data/ directory for data persistence when running compose locally
	@mkdir -p $@

container: .data ## start services locally
	@docker compose up -d


## Deployment
.PHONY: example-local example-development

example-local:	## Deploy locally to minikube via helm3 chart.
	@helm upgrade -i example ./helm/example --namespace example --create-namespace -f ./helm/localvalues.yaml --wait

example-development: 	## Deploy to kubernetes dev cluster via helm3 chart.
	@helm upgrade -i example ./helm/example --namespace example --create-namespace -f ./helm/devvalues.yaml \
	--set "image.tag=$(VERSION)" \
	--set "image.respository=$(REGISTRY)/$(IMAGE)" --wait

## extend as needed to other environments.