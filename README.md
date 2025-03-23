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

## Quick Start

 After you have the requirements set up above:

 1. make dev

or

 1. make build-infra
 2. make update-prod
 3. make prod