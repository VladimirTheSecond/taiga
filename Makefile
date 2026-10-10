# One-command lifecycle for the ephemeral Taiga stack.
# The persistent layer (state bucket, DNS zone, budget) lives in terraform/bootstrap/ and is not touched here.
#
#   make up                   staging certificate (default, avoids the Let's Encrypt rate limit)
#   make up STAGING=false     real certificate, use for the final run only
#   make timed-up             same as up, prints the wall-clock duration
#   make check                HTTPS, redirect, certificate issuer
#   make down                 destroy everything except the persistent layer
#
# Written for GNU Make 3.81 (the macOS default): no .ONESHELL, so every recipe line runs in
# its own shell. Commands that share state (cd, variables) are joined with && on one line.

SHELL := /bin/bash
.DEFAULT_GOAL := help

TF          := terraform -chdir=terraform
STAGING     ?= true
DOMAIN      := taiga.vladimirulasovets.de
# Vault password file is used if it exists, otherwise Ansible asks for the password.
VAULT_PASS_FILE ?= $(HOME)/.ansible/taiga-vault-pass
VAULT_ARGS  := $(if $(wildcard $(VAULT_PASS_FILE)),--vault-password-file $(VAULT_PASS_FILE),--ask-vault-pass)
# -k only for staging: its root CA is not in any trust store.
CURL        := curl -s -o /dev/null $(if $(filter true,$(STAGING)),-k)

.PHONY: help deps up timed-up infra configure check down

help: ## Show targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

deps: ## Install Ansible collections
	cd ansible && ansible-galaxy collection install -r requirements.yml

up: infra configure ## Create infrastructure and deploy Taiga
	@echo "Taiga is up: https://$(DOMAIN) (staging certificate: $(STAGING))"

timed-up: ## make up with a duration measurement
	@start=$$(date +%s) && \
	$(MAKE) up STAGING=$(STAGING) && \
	end=$$(date +%s) && \
	echo "make up took $$(( (end - start) / 60 ))m $$(( (end - start) % 60 ))s"

infra: ## terraform apply (also writes ansible/inventory/hosts.ini)
	$(TF) init -input=false
	$(TF) apply -auto-approve -input=false

# A new instance can reuse an old EIP: drop the stale host key so accept-new can trust the new one.
configure: ## Run the Ansible playbook against the generated inventory
	ssh-keygen -R "$$($(TF) output -raw server_public_ip)" >/dev/null 2>&1 || true
	cd ansible && ansible-playbook playbooks/site.yml $(VAULT_ARGS) -e '{"letsencrypt_staging": $(STAGING)}'

check: ## Verify redirect, HTTPS and certificate issuer
	@echo "--- certificate"
	@echo | openssl s_client -connect $(DOMAIN):443 -servername $(DOMAIN) 2>/dev/null | openssl x509 -noout -issuer -enddate
	@echo "--- http://  -> $$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' http://$(DOMAIN)/)"
	@echo "--- https:// -> $$($(CURL) -w '%{http_code}' https://$(DOMAIN)/)"
	@echo "--- api      -> $$($(CURL) -w '%{http_code}' https://$(DOMAIN)/api/v1/)"

down: ## Destroy the ephemeral stack (bootstrap stays)
	$(TF) destroy -auto-approve -input=false
