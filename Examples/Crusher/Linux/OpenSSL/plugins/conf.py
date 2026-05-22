"""
This configurator script provides differential fuzzing by replacing of target binaries in some instances with sanitized ones.
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
        opts = jops["options"]
        args = jops['target_args'] # target options (all after "--" in fuzzer run command)
        instance_name = jops['configuration']['instance_name']

        # Replace target binary
        if instance_name == 'FUZZ-IspFuzzerManager-SLAVE_0':
            args[0] = args[0].replace('fuzz', 'fuzz-asan')
            opts["delay"] = 500
            opts["timeout"]["value"] = 2000            
        elif instance_name == 'FUZZ-IspFuzzerManager-SLAVE_1':
            args[0] = args[0].replace('fuzz', 'fuzz-msan')
            opts["delay"] = 2000
            opts["timeout"]["value"] = 5000

        return json.dumps(jops)

    except Exception as ex:

        print("EXCEPTION!")
        traceback.print_exc()
        return None
