#!/bin/env bash
### Run this script after updating the mod to prepare a zip of it.

clear

### REPOSITORY is current working directory

current="$PWD"

repository="$(dirname "$(realpath "${BASH_SOURCE:-$0}")")/../"

source="$repository/Source"
info="$source/info.json"



cd "$repository"


### Get mod name and version from info.json
### https://stedolan.github.io/jq/

mod_name=`cat "$info" | jq --raw-output .name`
mod_ver=`cat "$info"| jq --raw-output .version`


### Prepare zip for Factorio native use and mod portal

name="${mod_name}_$mod_ver"
zip="$repository/$name.zip"


git clean -xdf

cd "$current"

7z a -xr'!.*' "$zip" "$source"
