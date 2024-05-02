# Introduction

This document lays out the choices and considerations undertaken while completing the Procare Online Platform engineering exercise. The approach taken will be explained in several sections.

# Caveats

Given that this is a take home exercise and there were issues getting access to my Heroku account, I've decided to demo this live with the interested parties, but I will lay out how the full demo setup should work and compare and contrast to a production setup.

# Github Actions

### Choice
Github Actions was chosen as the base for providing a CI/CD pipeline as opposed to a service such as CircleCI given that it is freely available for use on Github public repositories, which doesn't necessitate having to create a CircleCI account.

Note that for private repositories, Github Actions need to be paid for so that will need to be taken into consideration when determining which CI/CD approach to use for code deployment.

### CI/CD Build Pipeline

The CI/CD pipeline deployed for this example **Ruby on Rails CI** has several steps that determine whether or a build has succeeded successfully.

#### Checkout Code

This step checks out the latest version of the code made when creating a pull request into the main branch or merging code into the main branch.

#### Database Setup

This step ensures that the database is setup properly along with loading the database schema for the application.

#### RSpec Tests

This step runs all the RSpec tests for the application.  The build will stop here if the scan fails.

#### Brakeman Vulnerability Scanning

The step will run the Brakeman vulnerability scanner, which statically analyzes the application code for security issues. The build will stop here if the scan fails.

#### Rubocop Linting

Rubocop is used to do static code analysis on the application along with code formatting. It provides a basic guideline for how Ruby code should be styled. The build will stop here if the scan fails.

### Missing Steps

#### Synopsys Detect

Synopsys detect or a similar tool should be used for compositional analysis and vulnerability checking.

Sample Github Action integration

```
steps:
  - name: Create Black Duck Policy
    env:
      NODE_EXTRA_CA_CERTS: ${{ secrets.LOCAL_CA_CERT_PATH }}
    uses: blackducksoftware/create-policy-action@v0.0.1
    with:
      blackduck-url: ${{ secrets.BLACKDUCK_URL }}
      blackduck-api-token: ${{ secrets.BLACKDUCK_API_TOKEN }}
      policy-name: 'My Black Duck Policy For GitHub Actions'
      no-fail-if-policy-exists: true
  - name: Run Synopsys Detect
    uses: synopsys-sig/detect-action@v0.3.0
    env:
      NODE_EXTRA_CA_CERTS: ${{ secrets.LOCAL_CA_CERT_PATH }}
    with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        detect-version: 7.9.0
        blackduck-url: ${{ secrets.BLACKDUCK_URL }}
        blackduck-api-token: ${{ secrets.BLACKDUCK_API_TOKEN }}
```

References: 

[Synopsys Detect](https://sig-product-docs.synopsys.com/bundle/integrations-detect/page/introduction.html)

[Detect Action](https://github.com/synopsys-sig/detect-action)

#### Docker Image
Once all the previous steps have succeeded a docker image with a unique name should be created and deployed to a Docker repository of choice. This will be useful for keeping historical version of deployments and avoids having to re-run the entire CI/CD pipeline if a prior commit needs to be redeployed.

#### Heroku Deployment

Once the above build pipeline has succeeded another job would be triggered that would run a conditional deployment to a Heroku setup, asking for user permission for deployment.

Note that automatic deployments should be avoided as there may be multiple developers working on pull requests and merging code into the main branch. By asking for permission a safetly layer is added so people aren't deploying over someone else's changes.

Sample Github action integration

```
steps:
  - uses: akhileshns/heroku-deploy@v3.13.15 # This is the action
      with:
        heroku_api_key: ${{secrets.HEROKU_API_KEY}}
        heroku_app_name: "YOUR APP's NAME" #Must be unique in Heroku
        heroku_email: "YOUR EMAIL"
```

Reference: [Deploy to Heroku](https://github.com/marketplace/actions/deploy-to-heroku)

#### Load Testing and Performance Benchmarking

Another step should be added to the build pipeline which integrates performance testing into the CI/CD pipeline. This step should be performed after the related branch has been pushed to a staging/test environment.

One example of a piece of software that could be used to accomplish this is Grafana k6. Test scripts can be created and run through Github Actions. Performance objectives can be targeted by setting Pass/Fail criteria thresholds.

If any of the thresholds fail, then the pipeline should stop the build process.

This will help address the requirement requested by the business risk unit to ensure that the code being deployed meets certain benchmarks with regards to system response time.

Example:

Sample test.js

```
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  duration: '1m',
  vus: 50,
  thresholds: {
    http_req_failed: ['rate<0.01'], // http errors should be less than 1%
    http_req_duration: ['p(95)<500'], // 95 percent of response times must be below 500ms
  },
};

export default function () {
  const res = http.get('https://test.k6.io');
  sleep(1);
}
```

Sample Github action integration

```
steps:
  - name: Run local k6 test
      uses: grafana/k6-action@v0.2.0
      with:
        filename: test.js
```

Reference: [Load Testing Actions With Github](https://grafana.com/blog/2022/03/10/github-actions-load-testing/)

## Ideal Deployment Process

Ideally a service such as AWS Fargate or Azure Containers should be used to deploy and run Docker images that are created from the CI/CD pipelines. This will allow for a straight-forward deployment process which is manageable and allows for rollbacks as needed.

## Ideal Non Production Setup
This section explores one potential way of setting up a non production environment CI/CD process using Github Actions.

### Environment Definitions

In order to accomodate multiple environments, Github Actions and the repository should be configured with different environments for deployment

This will allow for each environment to have their own specific configuration and variables as needed.

Ideally deployments should be accomplished using Docker images that are artifacts from a properly executed build pipeline. This will allow for re-use of prior builds and enable quicker deployments to environments and for rolling back changes.

Two environments should initally be configured for non production deployment:
- qa (Used for developer/quality assurance testing)
- staging (Used for acceptance testing before deployment to production)

Any successful execution of the non production CI/CD pipeline should be paused at the deployment step with a request for approval. This will prevent issues of developers/qa personnel overwriting other deployments that may currently be in use.

Reference [Using environments for deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

## Ideal Production Setup

### Environment Definition

There should be a production environment defined with the proper configuration and variables as needed.

Any successful execution of the non production CI/CD pipeline should be paused at the deployment step with a request for approval. This approval step should have multiple required reviewers in order to ensure that there is agreement regarding a deployment.

### Differences from Non Production CI/CD Pipeline

The production deployment pipeline should be configured to work off git tags that are applied to the main branch which follow a specific format. (Ex. prod-20240502123456)

Ideally the person who commited a merge request into the main branch and tagged the related commit shouldn't be one of the reviewers for deployment approval.

Reference: [Reviewing Deployments](https://docs.github.com/en/actions/managing-workflow-runs/reviewing-deployments)

## Code/Repository Issues