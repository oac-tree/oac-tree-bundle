#! /usr/bin/env bash

branch=${1:-"master"}

git submodule foreach git fetch --all
git submodule foreach git checkout $branch
git submodule foreach git pull
