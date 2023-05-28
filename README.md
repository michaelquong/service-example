# service-example
Example service to demo CI/CD with Github Actions

## About  
The application is a simple Flask API app that uses a MySQL container as a persistent backend. It provides a simple interface to add, lookup, update and delete users by ID. The table model for users can be found in [models/users.py](./example/models/users.py). The model is used in combination with Flask-Migrate to handle migrations and upgrades to the users table during development and deployment. During container runtime, the table upgrades will automatically occur to ensure that the application's table migrations are up-to-date. New migration changes to the users table can be created using the command `make db/migrations` during development (and should be committed as part of PR), which will generate a new migration version in `migrations/versions/` directory.

The Application requires the following environment variables to be set at runtime:
```
db_name=appdb
db_user=appuser
db_password=changeme
MYSQL_SERVICE_HOST=localhost
MYSQL_SERVICE_PORT=3306
SECRET_KEY=somethingsupersecret
```
- `db_name` is the name of the database application is connecting to. 
- `db_user` and `db_password` is the credentials required to authenticate on connection to MySQL.
-  `MYSQL_SERVICE_HOST` and `MYSQL_SERVICE_PORT` specify the host and port for the MySQL service.
- `SECRET_KEY` is used in conjunction with a hashing algorithm to salt and hash passwords written to database


When using the MySQL latest container, the following environment variables are available to set up MySQL on startup:
```
MYSQL_ROOT_PASSWORD=changeme    # Required value for image
MYSQL_DATABASE=appdb            # Creates new database if it doesn't exist
MYSQL_USER=appuser              # Creates new application Super User
MYSQL_PASSWORD=changeme         # password to new user
```
Make sure to provide the necessary environment variables to configure the application and MySQL container properly.

## Development Environment
To set up your local development environment, follow these steps:
1. Create a virtual environment named `.venv` by running the following command:
    ```
    python3 -m venv .venv
    ```
2. Activate the virtual environment by running the following command:
    ```
    source .venv/bin/activate

    ### Note: If you're using Windows, the command to activate the virtual environment is slightly different:
    .venv\Scripts\activate
    ```
    Activating the virtual environment isolates your development environment and ensures that the dependencies you install are specific to this project.
3. Install the required application libraries by running the following command:
    ```
    pip install -r requirements.txt
    ```
    This command will install all the necessary libraries listed in the `requirements.txt` file.

By following these steps, you will have your local development environment set up with the required dependencies for the application.

## Running Application Locally
To run the application in a development environment, you can use the provided `docker-compose.yaml` file located at the root of the project. This file contains the necessary configuration to start the Flask API app and MySQL containers together. Please note that this setup is intended for development purposes and should not be used in a production environment. You may modify the environment values as needed during development.

To start the application with the default configuration, run the following command:
```
docker compose up
```
Alternatively, you can use the `make container` command, which does the same but with detached mode enabled:
```
make container
```
*Notes: Please be patient, as the MySQL container may take a moment to set up. The application will wait until MySQL is available to receive connections before starting.*

Once the application is ready, you can access the Flask API app at `http://localhost:5000`.

The `Dockerfile` included in the repository is a multi-staged Dockerfile. It separates the application runtime (labeled as `base`), libraries/dependencies (labeled as `libraries`), and service code. The `base` image manages the majority of the root-level requirements needed for the application to run. The dependencies listed in the `requirements.txt` file are installed with the `--user` flag to minimize potential library conflicts.

The `entrypoint.sh` script determines which web framework should be invoked based on the value of the `FLASK_ENV` environment variable. Currently, it supports two options: `development` (to run with Flask's built-in development server) or `production` (to run with Gunicorn). Additionally, any required upgrades to the users table will be automatically managed by this script.

## Application Deployment
Helm chart using Helm3 is available to facilitate Kubernetes like deployments. The main chart is under `helm/example/`. Overlay files to help override values.yaml depending on the environment deployment are available under `helm/` directory. Currently, only have an overlay for local deployment to Minikube and an overlay for deployment to Kubernetes (Not tested but acts as an example). Additional environment specific values can included.

*Notes: Chart Ingress has been tested with nginx-ingress controller as that comes default with Minikube. Chart does not come with nginx-ingress controller deployment. Expect to have ingress controllers deployed beforehand.*

### Deploying to Minikube
*Notes: Assume Minikube has already been installed correctly and is working. Additionally, require Docker and Kubectl.*

*Caveats: As we are not pushing images to a container registry, we need to ensure that Minikube is able to find our built application images locally, run the following commands:*
```
# Ensure local Minikube instance finds local images
eval $(minikube docker-env) # set environment

# use makefile command to build image with expected name and tag
make image  # build image specifically named and tagged as `my/$(IMAGE):latest`
```
*When deploying with helm `localvalues.yaml` will be used to override the `pullPolicy` such that we do not encounter `imagepullbackoff` errors.*

To deploy `nginx-ingress` controller in Minikube, run the following:
```
minikube addons enable ingress
```
*Notes: For external Kubernetes environments, please install a proper ingress controller as desired.*

The `ingress.yaml` in out templates is configured to point to `example.local` which is not a valid hostname url. To get this host url resolvable locally, find the Minikube IP address through one of the following methods:  
1. Using `kubectl` to describe our ingress object and look for the Address field in the output, which will contain the Minikube IP address.
    ```
    kubectl describe ingress -n example <ingress-name>
    ```
2. Using the Minikube command: Run the following command to get the Minikube IP address:
    ```
    minikube ip     # shows minikube IP address
    ```
Append an entry in your `/etc/hosts` file like the following:
```
$ cat /etc/hosts
...
<minikube IP>   example.local
...
```

To deploy with Helm to Minikube, run the following:
```
make example-local  # deploys helm chart locally on Minikube
```
Makefile target will install or upgrade `example` release in `example` namespace. Once release has been deployed, application will be available at `http://example.local`.

Chart, currently, is only meant for locally development and testing purposes only. The MySQL dependency Chart configurations have been set to `standalone` mode (No High Availability) and data storage persistence is disabled (No data persistence).


## Plans for Continuous Delivery & Continuous Deployment
Our project repository is hosted on GitHub, and we will leverage GitHub Actions to automate our CI/CD pipelines. GitHub Actions allows us to define workflows triggered by branch commits, enabling us to incorporate various CI stages. Here's our planned workflow:

1. **Code Style and Linting**: We'll use tools like `flake8` and `black` to enforce code style and perform linting, ensuring consistent and clean code.
2. **Unit Testing**: We'll utilize `Pytest` to run unit tests for each endpoint/route in our Flask app. These tests will verify the expected unit of behavior.
3. **Docker Image Compilation**: We'll compile our Dockerfile with the latest code changes, ensuring that our Docker image reflects the most up-to-date version of our application.

Our primary goal at this stage is to receive quick feedback on any changes pushed to the repository and ensure that they do not negatively impact the application's consistency and functionality.

For Continuous Delivery, we aim to automate the entire delivery process up to the point of deployment readiness. We will continue our workflow from the CI stages mentioned above:

4. **Integration Testing**: `Pytest` will also assist us in running integration tests. These tests will validate the interactions between different components of our application.

5. **Security Scanning**: We'll incorporate security scanning into our pipeline. Tools like `Bandit` will analyze our Python code for potential security vulnerabilities, while `Trivy` will scan our container images for any known vulnerabilities.

6. **Container Registry**: We'll push our Docker images to a container registry of our choice. GitHub's Container Registry at `ghcr.io` is a convenient option since our source code is already hosted on GitHub. Alternatively, we can consider using Artifactory or Nexus as popular alternatives.

7. **Test Deployment**: We'll deploy our application to a testing environment, allowing us to exercise our Helm chart configurations. This deployed environment will serve as the basis for subsequent testing stages.

8. **End-to-End Testing**: We'll run end-to-end testing suites using tools like `Postman`. Postman provides a user-friendly interface for sending requests to our API endpoints and validating the responses.

9. **Performance Testing**: To assess our application's performance, we'll employ `K6`, a well-documented and developer-centric performance testing suite written in JavaScript. K6 will provide detailed insights into the performance characteristics of our application.

10. **Promotion to Production**: Finally, we'll identify and promote container images that pass all the above criteria for production deployment.

Once automation pipeline maturity is reached, and we have met a threshold of confidence in our automated workflows. We can start discussions of Continuous deployments, maintaining the push model with our current setups or venture into more Gitops style with other Tool chains like ArgoCD.

## Future Enhancements
To further improve our solution, we have identified several areas where we can focus our efforts:

- **Secret Management**: Implement a secret lifecycle management tool like Hashicorp Vault to eliminate the use of long-lived passwords for MySQL connections. With Vault, we can establish a secret rotation policy and integrate it into our application. Consider implementing a sidecar Vault client or modifying the application to directly pull secret values from Vault. This ensures that secrets are securely managed and eliminates the reliance on fixed environment variables.
- **Monitoring**: Implement a monitoring solution to gain better insights into the performance and health of our application. Monitor metrics such as latency, traffic, error rates, and resource utilization. Tools like Prometheus and Grafana can be used to collect and visualize these metrics, allowing us to proactively identify and address any issues. Elastic Stacks can provide centralized logging and OpenTracing with Jaeger can provide insights into the request profile/performance.
- **Application Topology**: Review and optimize the application topology based on performance requirements. Identify the number of replicas needed to meet the desired performance limits. Additionally, update the MySQL topology to ensure high availability and accommodate the read/write performance requirements of the application.
- **Database Solution**: Evaluate the data requirements of the application and consider moving beyond the MySQL container on Kubernetes. Explore options such as using a MySQL Operator, managed MySQL services like AWS RDS with the MySQL engine, or configuring a custom solution using virtualization technologies. Choose a solution that best aligns with the scalability, performance, and data management needs of the application.
- **Data Layer Solution**: Consider the potential performance impacts of adopting a database ORM like SQLAlchemy. However, by using a database ORM, you benefit from built-in user input sanitization and improvement in code structure.

## Dev Tools
Developers can optionally use `pre-commit`, an automatic tool that runs styling and linting rules to ensure the project maintains a consistent style. It automatically analyzes and stylizes staged files on every commit, enforcing the defined rules. All rule violations must be corrected before the commits are allowed through. To opt-in, follow these steps:

1. Install `pre-commit` binary by running the following command:
    ```
    python -m pip install -r requirements-dev.txt
    ```
2. Setup all the rules outlined in the `.pre-commit-config.yaml` file by running:
    ```
    pre-commit install
    ```

By using `pre-commit`, developers can ensure that the codebase adheres to the defined style and quality standards, leading to more consistent and maintainable code. It also offers quicker feedback on basic styling and linting rules ran in automation workflows. Therefore, there is high confidence, those stages will pass.