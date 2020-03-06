# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown

# PROJECT_NAME defaults to name of the current directory.
# should not to be changed if you follow GitOps operating procedures.
PROJECT_NAME = $(notdir $(PWD))

# Note. If you change this, you also need to update docker-compose.yml.
# only useful in a setting with multiple services/ makefiles.
SERVICE_TARGET := main

# if vars not set specifially: try default to environment, else fixed value.
# strip to ensure spaces are removed in future editorial mistakes.
# tested to work consistently on popular Linux flavors and Mac.
ifeq ($(user),)
# USER retrieved from env, UID from shell.
HOST_USER ?= $(strip $(if $(USER),$(USER),nodummy))
HOST_UID ?= $(strip $(if $(shell id -u),$(shell id -u),4000))
else
# allow override by adding user= and/ or uid=  (lowercase!).
# uid= defaults to 0 if user= set (i.e. root).
HOST_USER = $(user)
HOST_UID = $(strip $(if $(uid),$(uid),0))
endif

THIS_FILE := $(lastword $(MAKEFILE_LIST))
CMD_ARGUMENTS ?= $(cmd)

# export such that its passed to shell functions for Docker to pick up.
export PROJECT_NAME
export HOST_USER
export HOST_UID

# all our targets are phony (no files to check).
.PHONY: shell help build rebuild service login test clean prune

# suppress makes own output
#.SILENT:

# shell is the first target. So instead of: make shell cmd="whoami", we can type: make cmd="whoami".
# more examples: make shell cmd="whoami && env", make shell cmd="echo hello container space".
# leave the double quotes to prevent commands overflowing in makefile (things like && would break)
# special chars: '',"",|,&&,||,*,^,[], should all work. Except "$" and "`", if someone knows how, please let me know!).
# escaping (\) does work on most chars, except double quotes (if someone knows how, please let me know)
# i.e. works on most cases. For everything else perhaps more useful to upload a script and execute that.
shell:
ifeq ($(CMD_ARGUMENTS),)
	# no command is given, default to shell
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) run --rm $(SERVICE_TARGET) sh
else
	# run the command
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) run --rm $(SERVICE_TARGET) sh -c "$(CMD_ARGUMENTS)"
endif

up:
	docker-compose up
down:
	docker-compose down

create-entity:
	docker-compose exec php bin/console make:entity --api-resource

dsu-force:
	docker-compose exec php bin/console doctrine:schema:update --force

dsu-dump:
	docker-compose exec php bin/console doctrine:schema:dump --force

generate_client:
	docker-compose exec client generate-api-platform-client