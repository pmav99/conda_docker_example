#!/usr/bin/env bash
#

set -xeuo pipefail

export DOCKER_BUILDKIT=1

# id gmes4africaproc
user_name='gmes4africaproc'
user_id=36042
group_id=50044

image_name=jeoreg.cidsn.jrc.it:5000/jeodpp-htcondor/gmes4africa_estation
version=0.1.0

exec docker build \
  --build-arg USER_NAME="${user_name}" \
  --build-arg USER_ID="${user_id}" \
  --build-arg GROUP_ID="${group_id}" \
  -t "${image_name}":"${version}" \
  -f Dockerfile \
  ./
