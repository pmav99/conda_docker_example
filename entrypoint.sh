#!/usr/bin/env bash
#

set -xeuo pipefail

# If you need to initialize the container on runtime do it here
# ...

# run the proper script
exec tini -- gosu "${USER_NAME}":"${USER_NAME}" conda run -n eStation2 python /usr/bin/jeodpp_batch_runner.py $"${@}"


# If you have multiple pythons scripts that you want to execute, you might use something like this:
#
# exec tini -- gosu "${USER_NAME}":"${USER_NAME}" conda run -n eStation2 python $"${@}"
#
# With this syntax you need to pass the name of the python script as an argument:
#
#     docker run <image_name> /usr/bin/jeodpp_batch_runner.py --help
#
# in this case, having an empty CMD would be OK, too.
