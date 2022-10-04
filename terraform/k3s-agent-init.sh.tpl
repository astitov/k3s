#!/bin/bash

curl -sfL https://get.k3s.io | sh -s - agent \
  --token=k3s \
  --server https://${master_ip}:6443
  
