-include .env

.PHONY: all remove venv

all :; remove install venv

venv :; python3 -m venv ./venv && source ./venv/bin/activate 

install :; bash install.sh

deactivate :; deactivate

activate :; source ./venv/bin/activate

clean :; rm -rf ./lib ./venv 

test :; pytest 

cloc :; cloc contracts/snek_raffle.vy --force-lang="Python"
