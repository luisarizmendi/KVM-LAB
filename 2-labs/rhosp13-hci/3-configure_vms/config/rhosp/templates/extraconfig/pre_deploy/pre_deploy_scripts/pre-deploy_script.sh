#!/bin/bash
#
set -x 

echo $(TZ=UTC date) >> /root/.timestamp_firstboot
