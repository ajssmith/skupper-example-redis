#!/bin/bash
skupper expose deployment redis-server --address redis-server-c
skupper expose deployment redis-sentinel --address redis-sentinel-c