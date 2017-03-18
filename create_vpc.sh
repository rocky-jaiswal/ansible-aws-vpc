#! /bin/sh

ansible-playbook playbook.yml -i hosts -e @vars.yml
