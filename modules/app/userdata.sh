#!/bin/bash

yum install python3.11-pip -y  &>>/opt/userdata.log
pip3.11 install botocore boto3  &>>/opt/userdata.log