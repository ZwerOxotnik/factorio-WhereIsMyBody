#!/bin/env bash
### Run this script after updating the mod to prepare a zip of it.


### REPOSITORY is current working directory

current=$PWD
repository="$(dirname -- $(readlink -fn -- "$0"; echo x))/../"

cd $repository


### Get mod name and version from info.json
### https://stedolan.github.io/jq/

mod_name=`cat info.json|jq -r .name`
mod_ver=`cat info.json|jq -r .version`


### Prepare zip for Factorio native use and mod portal

name="${mod_name}_$mod_ver"

git clean -xdf

cd $current

7z a -xr'!.*' "$repository/$name.zip" "$repository"
