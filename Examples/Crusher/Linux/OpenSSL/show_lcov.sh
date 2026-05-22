#!/bin/bash

work_dir=$(dirname $(realpath $0))

sudo chown $USER:$USER -R $work_dir/out
firefox $work_dir/out/EAT_OUT/results/common_results/coverage/result_html/index.html
