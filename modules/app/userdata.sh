#!/bin/bash

yum install ansible python3.11-pip -y  &>>/opt/userdata.log
pip3.11 install botocore boto3  &>>/opt/userdata.log
ansible-pull -i localhost, -U https://github.com/madhan-46/expense-ansible expense.yml -e service_name=${service_name} -e env=${env}  &>>/opt/userdata.log