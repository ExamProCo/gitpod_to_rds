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