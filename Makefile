# Get environment variables
ENV ?= $(shell aws configure get env)
COLOR ?= $(shell aws configure get color)
APPLICATION ?= $(shell aws configure get application)
REGION ?= $(shell aws configure get region)
VAR_FILE ?= vars/$(APPLICATION)-$(ENV)-$(COLOR)-$(REGION).tfvars

init:
	terraform init -var-file=$(VAR_FILE)

create:
	terraform workspace select $(APPLICATION)-$(ENV)-$(COLOR)-$(REGION)
	terraform apply -var-file=$(VAR_FILE)

delete:
	terraform workspace select $(APPLICATION)-$(ENV)-$(COLOR)-$(REGION)
	terraform destroy -var-file=$(VAR_FILE)