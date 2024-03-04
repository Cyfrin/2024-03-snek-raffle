-include .env

.ONESHELL:

.PHONY: all remove venv activate 

all :; remove install venv 

venv :; python3 -m venv ./venv

# remember to activate the virtual environment before running the following command
# source ./venv/bin/activate
install :; bash install.sh
# to deactivate the virtual environment, run `deactivate`

clean :; rm -rf ./lib ./venv 

test :; pytest 

cloc :; cloc contracts/snek_raffle.vy --force-lang="Python"
