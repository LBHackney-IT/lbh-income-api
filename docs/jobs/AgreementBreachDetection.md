# Agreement Breach Detection

The scheduled agreement state check runs every night at 4.00 am, see `schedule.yml`.

There is a number of days of tolerance before an agreement can be breached, to allow payments to go through.
The default value is 5 days, which can be overwritten by defining the environment variable on AWS:
- Define the number of days of tolerance before breach - **AWS ENV VARIABLE** `AGREEMENT_BREACH_TOLERANCE_DAYS`
