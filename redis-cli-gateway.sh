#!/bin/bash
skupper gateway init
skupper gateway forward redis-server-a 6379
skupper gateway forward redis-server-b 6380
skupper gateway forward redis-server-c 6381
skupper gateway forward redis-sentinel-a 26379
skupper gateway forward redis-sentinel-b 26380
skupper gateway forward redis-sentinel-c 26381