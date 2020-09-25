# LBH Income API

This application provides data to the [Income Collection - Manage Arrears Frontend][https://github.com/LBHackney-IT/LBH-IncomeCollection].

Data is provided to this application from various services/databases:
* [Tenancy API](https://github.com/LBHackney-IT/LBHTenancyAPI)
* Universal Housing Database - See [Universal Housing Simulator](https://github.com/LBHackney-IT/universal-housing-simulator)

It's responsibilities are:
* Maintain up-to-date records of tenancy agreements in arrears
* Provide next recommended actions on tenancy agreements
* Automate where possible recommended actions
* Provide information on tenancy agreements in arrears
* Maintain additional information on tenancy agreements
  - Payment Agreements
  - Court Case Outcomes
  - Eviction Dates
* Generating & Sending SMS (via Gov Notify)
* Generating & Sending Letters (via Gov Notify)
* Writing Action Diary events to Universal Housing as an audit trail

On a nightly basis it:
* Synchronises tenancy agreements in arrears, including migrating the following from UH
  - Court Cases
  - Eviction Dates
  - Payment Agreements
* Processes each tenancy to provide a next recommended action

## Technology

- Rails as a web framework.
- Puma as a web server.
- Sidekiq for running background and scheduled tasks.

## Development

See the [Development Guide](./docs/development/).

## Releasing

See the [Releasing Guide](./docs/development/Releasing.md).

## Jobs

This service regularly runs synchronisation and follow up actions. See [Jobs](./docs/jobs).

## Contacts

### Active Maintainers
- **Rashmi Shetty**, Development Manager at London Borough of Hackney (rashmi.shetty@hackney.gov.uk)
- **Miles Alford**, Engineer at London Borough of Hackney (miles.alford@hackney.gov.uk)

### Other Contacts
- **Antony O'Neill**, Lead Engineer at [Made Tech][made-tech] (antony.oneill@madetech.com)
- **Elena Vilimaitė**, Engineer at [Made Tech][made-tech] (elena@madetech.com)
- **Csaba Gyorfi**, Engineer at [Made Tech][made-tech] (csaba@madetech.com)
- **Ninamma Rai**, Engineer at [Made Tech][made-tech] (ninamma@madetech.com)
- **Soraya Clarke**, Relationship Manager at London Borough of Hackney (soraya.clarke@hackney.gov.uk)

[made-tech]: https://madetech.com/
