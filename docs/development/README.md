# Development

This project employs a variant of Clean Architecture, borrowing from [Made Tech Flavoured Clean Architecture][https://github.com/madetech/clean-architecture].

## Environment Setup

1. Install [Docker CE][https://www.docker.com/products/docker-desktop].
2. Get a hackney aws account (speak to an active maintainer)
3. Clone this repository.
4. Login to ECR to get the [Universal Housing Simulator][https://github.com/LBHackney-IT/lbh-universal-housing-simulator] image.
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

## Serving the app locally

To serve the application, run the following and visit [http://localhost:3000](http://localhost:3000).

```sh
$ make serve
```

## Testing

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

## Linting

"Linters" run static analysis on code to ensure it meets style standards. We use [Rubocop][https://github.com/rubocop-hq/rubocop] on this project with a permissive configuration.

```
$ make lint
```

You can use the following to ensure your changes are deployable, in that they are passing the automated test suite and have no code style issues.

```
$ make check
```
