"""
This configurator script provides for firefox unique value of "-P" (profile) option.
This avoids conflicts when multiple firefox instances are running.
We assume that these profiles already exist - they must be created manually or with environment script (env.py),
which is run before this script.
"""

import json
import traceback
import os

# Set profiles dir
stend_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir)
# you can set directory you want
#profiles_dir = os.path.join(stend_dir, 'target', 'profiles')

log_file = os.path.join(stend_dir, 'tmp', 'env.log')


def transform_options(ops_json):
    """
    Transform fuzz/eat options
    :param ops_json: options from fuzz/eat in dict format
    :return: modified options
    """
    try:
        # Parse options
        jops = json.loads(ops_json)
        args = jops['target_args'] # target options (all after "--" in fuzzer run command)
        instance_name = jops['configuration']['instance_name']

        # Replace target binary
        if instance_name == 'FUZZ-SLAVE_0':
            args[0] = args[0].replace('afl', 'afl-asan')
        elif instance_name == 'FUZZ-SLAVE_1':
            args[0] = args[0].replace('afl', 'afl-msan')

        return json.dumps(jops)

    except Exception as ex:

        print("EXCEPTION!")
        traceback.print_exc()
        return None
