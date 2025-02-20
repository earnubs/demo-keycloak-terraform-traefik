# MacOS

Create a tfvars file with the extension `auto.tfvars`, e.g. `local-mac.auto.tfvars`,
set the docker host to match your Docker container runtime host (`colima status`).

```tf
docker_host = "unix:///Users/sstewart/.colima/default/docker.sock"
```
