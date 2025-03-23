# ------------------
# ANSIBLE-MAKEFILE v0.16.0
# Run ansible commands with ease
# ------------------
#
# Copyright (C) 2017 Paul(r)B.r
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ------------------
#
# Modified by jfritz 3/22/2025 for use with h-equals-h-ws
# Source available at http://github.com/jfritz/h-equals-h-ws
# 
# ------------------

SHELL:=/bin/bash

##
# VARIABLES
##
playbook   ?= setup
roles_path ?= "roles/"
env        ?= hosts
mkfile_dir ?= $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ifeq ("$(wildcard $(mkfile_dir)pass.sh)", "")
  opts     ?= $(args)
else # Handle vault password if any
  ifeq ("$(shell $(mkfile_dir)pass.sh 2> /dev/null)", "")
    opts     ?= $(args)
  else
    opts     ?= $(args) --vault-password-file=$(mkfile_dir)pass.sh
  endif
endif
ifneq ("$(limit)", "")
  opts     := $(opts) --limit="$(limit)"
endif
ifneq ("$(tag)", "")
  opts     := $(opts) --tag="$(tag)"
endif

##
# TASKS
##

# Login to aws: 
# https://docs.aws.amazon.com/cli/latest/userguide/cli-authentication-short-term.html
# needs ~/.aws/credentials

# TODO make infra-template and implement make template?
# TODO make load-test

# Make build-infra - launch ec2 instance from template and log current aws instance., creates .aws_instance_id
.PHONY: build-infra
build-infra:
	aws ec2 run-instances \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=h-equals-h-ws}]' \
	--launch-template LaunchTemplateName=h-equals-h-uat-templ --output json | \
	grep InstanceId | cut -d ":" -f2 | cut -d "\"" -f2 > $(mkfile_dir)/.aws_instance_id
	@cat $(mkfile_dir)/.aws_instance_id
#             "InstanceId": "i-0efeae13e56df1064",

# Make clean-infra - destroy ec2 instance (configure to destroy EBS as well)
# Don't run this after you go to production! Set termination protection on your prod instance
.PHONY: clean-infra
clean-infra:
	aws ec2 terminate-instances --instance-ids $(shell cat $(mkfile_dir)/.aws_instance_id)
	rm .aws_public_ip .aws_instance_id

#  Make update-prod - ensures prod ip is in prod inventory, creates .aws_public_ip
.PHONY: update-prod
update-prod:
	cd $(mkfile_dir)
	$(eval instance_id = $(shell cat .aws_instance_id))
	@echo $(instance_id)
	$(eval heqh_pub_ip = $(shell aws ec2 describe-instances --instance-ids $(instance_id) --query 'Reservations[*].Instances[*].PublicIpAddress' --output text))
	sed -i '.bak' -r 's/^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/$(heqh_pub_ip)/g' hosts/prod/inventory 
	echo $(heqh_pub_ip) > .aws_public_ip
	@head -n2 hosts/prod/inventory

# Make prod - deploy ansible to prod
.PHONY: prod
prod:
	cd $(mkfile_dir)/playbooks && ANSIBLE_CONFIG=$(mkfile_dir)/ansible-timer-only.cfg ansible-playbook -i ../hosts/prod/inventory setup.yml

# Make dev - deploy ansible to dev
.PHONY: dev
dev:
	cd $(mkfile_dir)/playbooks && ANSIBLE_CONFIG=$(mkfile_dir)/ansible-timer-only.cfg ansible-playbook -i ../hosts/dev/inventory setup.yml

# make ssh-prod - access prod via ssh
.PHONY: ssh-prod
ssh-prod:
	$(eval pub_ip = $(shell cat .aws_public_ip))
	$(eval keypath = $(shell grep -i ansible_ssh_private_key_file $(mkfile_dir)/hosts/prod/inventory | cut -d"=" -f2))
	ssh -i $(keypath) admin@$(pub_ip)

# make debug - use this for random testing
.PHONY: debug
debug:
	cd $(mkfile_dir)/playbooks && ANSIBLE_CONFIG=$(mkfile_dir)/ansible-timer-only.cfg ansible-playbook -i ../hosts/prod/inventory -t db setup.yml

# .PHONY: install
# install: ## make install [roles_path=roles/] # Install roles dependencies
# 	@ansible-galaxy install --ignore-errors --roles-path="$(roles_path)" --role-file="requirements.yml" $(opts)

# .PHONY: fetch-inventory
# fetch-inventory: ## make fetch-inventory [provider=<ec2|gce...>] [env=hosts] # Download dynamic inventory from Ansible's contrib
# 	@wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/$(provider).py
# 	@chmod +x $(provider).py
# 	mv $(provider).py $(env)

# .PHONY: inventory
# inventory: inventory-graph ## make inventory [env=hosts] # LEGACY replaced by inventory-graph

# .PHONY: inventory-graph
# inventory-graph: ## make inventory-graph [env=hosts] # Display the inventory as seen from Ansible
# 	@env=$(env) ansible-inventory --graph -i $(env) $(opts)

# .PHONY: inventory-list
# inventory-list: ## make inventory-list [env=hosts] # Display the inventory as seen from Ansible
# 	@env=$(env) ansible-inventory --list -i $(env) $(opts)

# .PHONY: lint
# lint: ## make lint [playbook=setup] [env=hosts] [args=<ansible-playbook arguments>] # Check syntax of a playbook
# 	@env=$(env) ansible-playbook --inventory-file="$(env)" --syntax-check $(opts) "$(playbook).yml"

# .PHONY: debug
# debug: mandatory-host-param ## make debug host=hostname [env=hosts] [args=<ansible arguments>] # Debug a host's variable
# 	@env=$(env) ansible -i $(env) $(opts) -m setup $(host)
# 	@env=$(env) ansible --inventory-file="$(env)" $(opts) --module-name="debug" --args="var=hostvars[inventory_hostname]" $(host)

# .PHONY: dry-run
# dry-run: ## make dry-run [playbook=setup] [env=hosts] [tag=<ansible tag>] [limit=<ansible host limit>] [args=<ansible-playbook arguments>] # Run a playbook in dry run mode
# 	@env=$(env) ansible-playbook --inventory-file="$(env)" --diff --check $(opts) "$(playbook).yml"

# .PHONY: run
# run: ## make run [playbook=setup] [env=hosts] [tag=<ansible tag>] [limit=<ansible host limit>] [args=<ansible-playbook arguments>] # Run a playbook
# 	@env=$(env) ansible-playbook --inventory-file="$(env)" --diff $(opts) "$(playbook).yml"

# group ?=all
# .PHONY: list
# list: ## make list [group=all] [env=hosts] # List hosts inventory
# 	@env=$(env) ansible --inventory-file="$(env)" $(group) --list-hosts

# .PHONY: vault
# vault: mandatory-file-param ## make vault file=/tmp/vault.yml [env=hosts] [args=<ansible-vault arguments>] # Edit or create a vaulted file
# 	@[ -f "$(file)" ] && env=$(env) ansible-vault edit $(opts) "$(file)" || \
# 	env=$(env) ansible-vault create $(opts) "$(file)"

# .PHONY: console
# console: ## make console [env=hosts] [args=<ansible-console arguments>] # Run an ansible console
# 	@env=$(env) ansible-console --inventory-file="$(env)" $(opts)

# group ?=all
# .PHONY: facts
# facts: ## make facts [group=all] [env=hosts] [args=<ansible arguments>] # Gather facts from your hosts
# 	@env=$(env) ansible --module-name="setup" --inventory-file="$(env)" $(opts) --tree="out/" $(group)

# .PHONY: cmdb
# cmdb: ## make cmdb # Create HTML inventory report
# 	@ansible-cmdb "out/" > list-servers.html

# .PHONY: bootstrap
# bootstrap: ## make bootstrap # Install ansible (Ubuntu only)
# 	@apt-get install -y software-properties-common && \
# 	apt-add-repository ppa:ansible/ansible && \
# 	apt-get update && \
# 	apt-get install -y ansible

# .PHONY: mandatory-host-param mandatory-file-param
# mandatory-host-param:
# 	@[ ! -z $(host) ]
# mandatory-file-param:
# 	@[ ! -z $(file) ]

# help:
# 	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# .DEFAULT_GOAL := help