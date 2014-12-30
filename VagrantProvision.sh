#!/usr/bin/env bash

# Add the repository
sudo rpm -Uvh http://repo.webtatic.com/yum/centos/5/latest.rpm

# Install the latest version of git
yum install -y --enablerepo=webtatic git-core
