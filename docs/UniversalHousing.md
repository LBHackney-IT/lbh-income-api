# Universal Housing

Universal Housing still contains a lot of data that this service is reliant on.

## Connection

Universal Housing configuration is given through environment variables, for example using development details:

- UH_DATABASE_NAME=StubUH
- UH_DATABASE_USERNAME=sa
- UH_DATABASE_PASSWORD=Rooty-Tooty
- UH_DATABASE_HOST=universal_housing
- UH_DATABASE_PORT=1433

## Simulator

We use a [Universal Housing simulator][https://github.com/LBHackney-IT/lbh-universal-housing-simulator] to run automated tests against, mirroring the structure of the legacy Universal Housing database.
