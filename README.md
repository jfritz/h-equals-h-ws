# h-equals-h website Ansible build

## Dev Environment Setup

### MacOS
1. Install homebrew
2. brew install pipx
3. Install ansible `pipx install --include-deps ansible`
4. Install ansible-lint `pipx install ansible-lint`
5. `brew install sshpass` # for using password ssh auth to remote node
6. Follow instructions at all steps to update $PATH.
7. Install aws cli v2
8. Authenticate using .aws/credentials with key made on IAM user in AWS console. IAM user needs EC2 permissions.
9. Test aws cli with a test command

### AWS 

NOTE: Only prod builds use aws. Local builds assume local debian VM is running and accessible. Ensure that: 

1. AWS launch template named properly (see Makefile make-infra) and uses Debian 12,
1. You have private key for ec2 auth set up in .ssh/*.pem and set that path in the prod inventory
1. AWS elastic IP associated with network adapater for instance that will spin up from template (if permanent static IP required)
1. Proper DNS config in Route 53 and your domain name registrar
1. Production/dev inventories set up for ansible

### Running Builds

 After you have the requirements set up above:

 1. make dev

or

 1. make build-infra
 2. make update-prod
 3. make prod

 ### Production HTTPS Cert Setup
 See https://wiki.debian.org/Lighttpd#SSL.2FTLS_.28HTTPS.29
 TODO once done, save off certs for future import in case of server rebuild. if you need to rebuild you'll have to reupdate TXT records in DNS route53