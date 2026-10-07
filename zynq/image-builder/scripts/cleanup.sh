#!/bin/bash

apt-get clean
rm -rf /var/lib/apt/lists/*

find /usr/share/doc -mindepth 1 -not -name copyright -not -type d -delete
rm -rf /usr/share/man/* /usr/share/info/* /usr/share/lintian/*
find /usr/share/locale -mindepth 1 -maxdepth 1 -not -name locale.alias -exec rm -rf {} +
