# Syncing Tenancies In Arrears

Each morning this service will sync attributes from UH on tenancies that are in arrears.

During processing of Rental tenancies it:

* Migrates court cases
* Migrates eviction dates
* Migrates Agreements
* Detects agreement breaches
* Recommends a next action
* Attempts to send letters automatically

## Re-running Sync

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
