# LBH Income API

## Setup

1. Clone the following repo (private sorry) into your parent directory.
    * https://github.com/LBHackney-IT/lbh-universal-housing-simulator

2. run `make build`

## Development

To serve the application, run the following and visit [http://localhost:3000](http://localhost:3000)

```sh
$ make serve
```

To run tests:

```sh
$ make test
```

If you're TDDing code, it can sometimes be faster to boot up the app container once, then run tests within it. That way you don't have to start the docker container every time you run tests:

```sh
# start the docker container
$ make serve

# in a separate tab, run this to get a shell within the docker container
$ make shell

# run rspec after every change in the docker container shell
$ rspec
```

The above is useful because you can TDD your change and manually test through the browser without having to restart anything.

## Connection to Universal Housing

Universal Housing configuration is given through environment variables, for example using development details:

- UH_DATABASE_NAME=StubUH
- UH_DATABASE_USERNAME=sa
- UH_DATABASE_PASSWORD=Rooty-Tooty
- UH_DATABASE_HOST=universal_housing
- UH_DATABASE_PORT=1433

When developing locally, the docker compose configuration assumes that the [Universal Housing simulator](https://github.com/LBHackney-IT/lbh-universal-housing-simulator) is checked out in the same directory as this.
