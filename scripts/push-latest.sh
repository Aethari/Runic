#!/bin/bash

# Update the "latest" branch with the current state of the "master" branch
git checkout latest
git reset --hard master
git push --force origin latest
