# LBH Income API

The Income API is the backend of the [Income Collection Service][github-ics], and connects to the legacy Universal Housing database and the [Tenancy API][github-tenancy-api].

It is used to store users, prioritise cases, assign cases evenly to users, and retrieve information about those cases.

## Stack

- Rails as a web framework.
- Puma as a web server.
- Sidekiq for running background and scheduled tasks.

## Development practices

We employ a variant of Clean Architecture, borrowing from [Made Tech Flavoured Clean Architecture][mt-ca].

## Contributing

### Setup

1. Install [Docker][docker-download].
2. Get a hackney aws account (see maintainers)
3. Clone this repository.
4. Login to ecr to get the [Universal Housing Simulator][github-uh-simulator] [1] image.
  * On aws version 1
    ```bash
    $ aws configure
    $ bash <(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)
    ```
  * On aws version 2
    ```bash
    $ aws ecr \
        get-login-password --region eu-west-2 \
        | docker login \
            --username AWS \
            --password-stdin \
            775052747630.dkr.ecr.eu-west-2.amazonaws.com
    ```
5. Duplicate `.env.sample` to `.env` and replace placeholders with valid secrets.
6. Run setup

```bash
make setup
```

[1] Need to login to your AWS Hackney account; if you have another you will need to use Profiles

### Development

#### Serving the app locally

To serve the application, run the following and visit [http://localhost:3000](http://localhost:3000).

```sh
$ make serve
```

#### Testing

To reset your test database run

```sh
$ make test-db-destroy
```

To run tests:

```sh
$ make test
```

To run linting and tests:

```sh
$ make check
```

If you're TDDing code, it can sometimes be faster to boot up the app container once, then run tests within it. That way you don't have to start the Docker container every time you run tests:

```sh
# in a separate tab, run this to get a shell within the Docker container
$ make shell

# run rspec after every change in the Docker container shell
$ rspec

# or for one file
$ rspec path/to/spec
```

The above is useful because you can TDD your change and manually test through the browser without having to restart anything.

If you find that when running tests, UH simulator keeps dying, it might be because you need to [assign more memory to Docker](https://docs.docker.com/docker-for-mac/#preferences) (this link is specifically for macs, but other operating systems might be similar).

#### Linting

"Linters" run static analysis on code to ensure it meets style standards. We use [Rubocop][rubocop] on this project with a permissive configuration.

```
$ make lint
```

You can use the following to ensure your changes are deployable, in that they are passing the automated test suite and have no code style issues.

```
$ make check
```

### Release

![Circle CI Workflow Example](docs/circle_ci_workflow.png)

We use a pull request workflow, where changes are made on a branch and approved by one or more other maintainers before the developer can merge into `master`.

Then we have an automated four step deployment process, which runs in CircleCI.

1. Automated tests (RSpec) and linting (Rubocop) are run to ensure the release is of good quality.
2. The app is deployed to staging automatically, where we check our latest changes work well.
3. We manually confirm a production deployment in the CircleCI workflow once we're happy with our changes in staging.
4. The app is deployed to production.

#### Manual Redeployment

1. Browse to the `master` branch on GitHub.
2. Browse to 'Commits'.
3. Locate and click the checks indicator for the commit you would like to deploy from.
4. Click a stage's 'Details' link.
5. Confirm the commit SHA is the same
  5.1. On Circle CI, the hash is shown on the right-hand side of the page, under 'Triggered by'.
  5.2. Compare this with the hash shown in the commits list.
6. Once you are happy, click 'Rerun workflow' on Circle CI.
7. There are **manual stages** that need to be triggered within the workflow.
Remember to do this, or the new workflow/deployment will not make it to production.

### Connection to Universal Housing

Universal Housing configuration is given through environment variables, for example using development details:

- UH_DATABASE_NAME=StubUH
- UH_DATABASE_USERNAME=sa
- UH_DATABASE_PASSWORD=Rooty-Tooty
- UH_DATABASE_HOST=universal_housing
- UH_DATABASE_PORT=1433

We use a [Universal Housing simulator][github-uh-simulator] to run automated tests against, mirroring the structure of the legacy Universal Housing database.

## Cloud Storage and KMS (Key Management System)

The letters generated (PDF files) will be saved in S3 using Client-Side Encryption with Aws KMS.

The Cloud Storage solution make use of the following ENV variables:

- AWS_ACCESS_KEY_ID
- AWS_REGION
- AWS_SECRET_ACCESS_KEY
- CUSTOMER_MANAGED_KEY

Those keys need to be different for staging and production enviroments.

In addition, 2 different users(or roles) are needed to manage the Customer Managed Key:

- A user with permissions to manage the keys
- A user with permissions to use the keys (to encrypt/decrypt document)

For more: [AWS Client Side encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html)

## Background Workers

We use Sidekiq to perform background jobs and act as a scheduler (`cron`).

See `schedule.yml` for the definitions of what `cron` jobs we run. Read the [Sideqik Scheduler Docs](https://github.com/moove-it/sidekiq-scheduler) for how to setup a scheduled job.

If you need to add environment variables, you need to update the ECS Task Definition.

## Automation of Sending Letters

This section is regarding the automation of how we send letters to tenants. The automation process is broken down into various customisable sections which make up this feature.

The `automate_sending_letters` orchestrator use case is where the code lives `lib/use_cases/automate_sending_letters.rb`

You have the flexibility to change the automation settings within AWS, you can:

- Turn on and off automation - **AWS ENV VARIABLE** `CAN_AUTOMATE_LETTERS`
- Turn on and off automation for income collection Letter 1 - **AWS ENV VARIABLE** `AUTOMATE_INCOME_COLLECTION_LETTER_ONE`
- Turn on and off automation for income collection Letter 2 - **AWS ENV VARIABLE** `AUTOMATE_INCOME_COLLECTION_LETTER_TWO`
- Add or remove patches which can allow for automation - **AWS ENV VARIABLE** `PATCH_CODES_FOR_LETTER_AUTOMATION`

The AWS variables are the same across staging and production.

In order to change any of these variables you will need to:

1. Login to AWS
2. Go to **ECS**
3. Locate and select **Task Definitions** on the left-hand sidebar
4. Search for `task-income-` in the 'Filter in this page' field above the table.
5. Select `income-api-production` or `income-api-staging`.
6. Click on the Task definition you'd like to base your new one off.
This will usually be the most recent, i.e. the one with the greatest tag number.
7. Click **Create new revision**
8. Locate 'Container definitions' and select the `income-api-production-worker` container.
9. Locate the 'ENVIRONMENT' section of the slide-out.
10. Add/Modify the relevant Environment Variables.
11. Click **Update** at the bottom of the slide-out when you have finished making changes/additions.
12. Click **Create** at the bottom of the 'Create new revision' page.
13. Verify that the Environment Variables have been inputted correctly, to check this click on the **JSON** tab of the newly created task definition
14. Check that all the Environment Variables are correct, look for issues such as trailing whitespace e.g. `AUTOMATE_INCOME_COLLECTION_LETTER_ONE\t` (i.e. trailing \<TAB\> character) or special characters.
15. If you find any issues with any of the Environment Variables, follow the above steps to create a new Task Definition with the correct ones.
16. There is now a new Task Definition, but it has not been applied yet.
**You must ENSURE YOU [REDEPLOY](#manual-redeployment) to have your changes applied**

**IMPORTANT: IF YOU UPDATE THE TASK DEFINITION BY CHANGING ANY OF THE ABOVE YOU NEED TO REDEPLOY IN ORDER FOR THE NEW INSTANCE TO USE THE NEW TASK DEFINITION**

## Automation of agreement state checks
The scheduled agreement state check runs every night at 4.00 am, see `schedule.yml`.

There is a number of days of tolerance before an agreement can be breached, to allow payments to go through.
The default value is 5 days, which can be overwritten by defining the environment variable on AWS:
- Define the number of days of tolerance before breach - **AWS ENV VARIABLE** `AGREEMENT_BREACH_TOLERANCE_DAYS`


### Re-running Sync

1. You first need to SSH onto the ECS instance
> #### TODO
> - Who to talk to
> - Instance?
> - SSH key
2. You will need to run commands on the `income-api-*-worker`.
Run an interactive terminal on the container:
```
$ docker ps
$ docker exec -it <CONTAINER_ID> bash
```
3. Verify that you are on the correct container, in the correct environment, etc. E.g.
```
$ echo $RAILS_ENV
$ echo $CAN_AUTOMATE_LETTERS
```
4. Enqueue the sync `Rake` task.
```
$ bundle exec rake income:sync:enqueue
```
5. Verify that the sync is running.

## Debugging Production

### Accessing a worker instance

The income-api runs in an a docker container in ECS. To access a container you'll first need to access the docker EC2
host. This can be done by investigating the docker cluster in ECS and getting a valid SSH key.

Once you're on the cluster worker, you can list the docker instances using a filter.

Here's an example for listing the production workers.
```bash
[ec2-user@ip- ~]$ docker ps --filter 'name=income-api-production-worker'
CONTAINER ID        IMAGE                                                                             COMMAND                  CREATED             STATUS              PORTS               NAMES
0a40e6ad57a5        775052747630.dkr.ecr.eu-west-2.amazonaws.com/hackney/apps/income-api:production   "entrypoint.sh sh -c…"   6 days ago          Up 6 days           3000/tcp            ecs-task-income-api-production-198-income-api-production-worker-b4b9f786d7d9f2b42f00
```

You can then run commands on the worker using a command like this, replacing `env` with `bash` if you'd rather get a shell prompt
```bash
docker exec --tty --interactive $(docker ps --quiet --filter 'name=income-api-production-worker') env
```

## Contacts

### Active Maintainers

- **Rashmi Shetty**, Development Manager at London Borough of Hackney (rashmi.shetty@hackney.gov.uk)
- **Vlad Atamanyuk**, Junior Developer at London Borough of Hackney (vladyslav.atamanyuk@hackney.gov.uk)
- **Steven Leighton**, Engineer at [Made Tech][made-tech] (steven@madetech.com)
- **Elena Vilimaitė**, Engineer at [Made Tech][made-tech] (elena@madetech.com)
- **George Schena**, Engineer at [Made Tech][made-tech] (george@madetech.com)

### Other Contacts

- **Richard Foster**, Lead Engineer at [Made Tech][made-tech] (richard@madetech.com)
- **Luke Morton**, Director at [Made Tech][made-tech] (luke@madetech.com)
- **Dennis Robinson**, Delivery Lead at London Borough of Hackney (dennis.robinson@hackney.gov.uk)
- **Soraya Clarke**, Delivery Manager at London Borough of Hackney (soraya.clarke@hackney.gov.uk)

[github-uh-simulator]: https://github.com/LBHackney-IT/lbh-universal-housing-simulator
[github-ics]: https://github.com/LBHackney-IT/LBH-IncomeCollection
[github-tenancy-api]: https://github.com/LBHackney-IT/LBHTenancyAPI
[docker-download]: https://www.docker.com/products/docker-desktop
[mt-ca]: https://github.com/madetech/clean-architecture
[made-tech]: https://madetech.com/
[rubocop]: https://github.com/rubocop-hq/rubocop
