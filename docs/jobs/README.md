# Jobs

We use Sidekiq to perform background jobs and act as a scheduler (`cron`).

See `schedule.yml` for the definitions of what `cron` jobs we run. Read the [Sideqik Scheduler Docs](https://github.com/moove-it/sidekiq-scheduler) for how to setup a scheduled job.

If you need to add environment variables, you need to update the ECS Task Definition.
