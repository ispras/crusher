#!/bin/bash
sydr -o /suricata-sydr/results-async -f /labs/suricata/suricata-verify/tests/http-async-cli/input.pcap  -l debug -- /labs/suricata/suricata/src/fuzz_decodepcapfile /labs/suricata/suricata-verify/tests/http-async-cli/input.pcap
