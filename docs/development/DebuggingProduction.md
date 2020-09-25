# Debugging Production

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
