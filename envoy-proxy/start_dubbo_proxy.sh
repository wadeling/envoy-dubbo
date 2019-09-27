#!/bin/bash

#cp
cp -af ~/go/src/github.com/envoyproxy/envoy/bazel-bin/source/exe/envoy-static ./

#start
./envoy-static -c config.yaml -l trace
