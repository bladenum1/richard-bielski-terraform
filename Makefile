# Get environment variables
ENV ?= $(shell aws configure get env)
COLOR ?= $(shell aws configure get color)
APPLICATION ?= $(shell aws configure get application)
REGION ?= $(shell aws configure get region)
VAR_FILE ?= vars/$(APPLICATION)-$(ENV)-$(COLOR)-$(REGION).tfvars

init:
	terraform init -var-file=$(VAR_FILE)

clean:
	rm CICD/modules/lambda/src/main
	rm CICD/modules/lambda/src/main.zip

create-base:
	terraform workspace select $(APPLICATION)-$(ENV)-$(COLOR)-$(REGION)
	terraform apply -var-file=$(VAR_FILE)

delete:
	terraform workspace select $(APPLICATION)-$(ENV)-$(COLOR)-$(REGION)
	terraform destroy -var-file=$(VAR_FILE)

create-cicd: compile-lambda
	cd CICD && terraform workspace select $(APPLICATION)-$(ENV)-$(COLOR)-$(REGION)
	cd CICD && terraform apply -var-file=../$(VAR_FILE)

delete-cicd:
	cd CICD && terraform workspace select $(APPLICATION)-$(ENV)-$(COLOR)-$(REGION)
	cd CICD && terraform destroy -var-file=../$(VAR_FILE)

compile-lambda:
	cd CICD/modules/lambda/cmd/ && go mod tidy && GOOS=linux GOARCH=amd64 go build -o main main.go
	zip -j CICD/modules/lambda/cmd/main.zip CICD/modules/lambda/cmd/main
