# Gitpod-To-RDS

Since Gitpod IP's change all the time.
This is so you can whitelist the IP address to gain access
to your publically available RDS instance.

```rb
require 'gitpod_to_rds'
namespace :db do
  desc "Open Ingress Rule for Gitpod Workspace"
  task :ingress_for_gitpod do |t|
    GitpodToRds.run({
      sg_id: 'sg-0e459f4c80bef8aa2', 
      ip_protocol: 'tcp',
      from_port: 5432, 
      to_port: 5432, 
      description: 'GITPOD', 
      ip_address: ENV['MY_GITPOD_IP']
    })
  end
```

## Get your IP Address

eg. https://8080-examproco-gitpodtords-ztjowhzyqir.ws-us84.gitpod.io

> you might need to remove the trailing forward slash

You can use a service such as this:
https://whatismyipaddress.com/hostname-ip


Results:
Lookup Hostname: 8080-examproco-gitpodtords-gs85lhv020s.ws-us84.gitpod.io
Lookup IPv4 Address: 34.168.130.220

exp-bootcamp.cglotc3n8hbn.us-east-1.rds.amazonaws.com
postgres

postgresql://postgres:$8pgXNVty.Al[ZGY18$Kav0vN8vH@exp-bootcamp.cglotc3n8hbn.us-east-1.rds.amazonaws.com:5432/exp_bootcamp