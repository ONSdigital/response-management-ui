#!/bin/sh
#
# Script for running both the mock Action and Case web services.
# Both processes are started in the background. Use Ctrl + C to terminate.
#
# Usage: run.sh
#
# Author: John Topley (john.topley@ons.gov.uk)
#
nohup bundle exec rackup -p 8151 ./actionservice/config.ru &
action_pid=$!

nohup bundle exec rackup -p 8171 ./caseservice/config.ru &
case_pid=$!

# Trap SIGINTs so we can send them back to $action_pid and $case_pid.
trap "kill -2 $action_pid" 2
trap "kill -2 $case_pid" 2

# In the meantime, wait for $action_pid and $case_pid to end.
wait $action_pid
wait $case_pid
