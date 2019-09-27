#!/bin/bash

#cp
cp -a -f ~/go/src/github.com/wadeling/envoy/bazel-bin/source/exe/envoy-static ./

#start
./envoy-static -c config.yaml -l trace
