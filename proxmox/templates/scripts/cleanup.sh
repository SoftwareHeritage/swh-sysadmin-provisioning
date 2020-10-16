#!/bin/bash -eu

# Disable installer user
usermod -L installer
chsh -s /usr/sbin/nologin installer
