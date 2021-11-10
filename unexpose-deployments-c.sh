#!/bin/bash
skupper unexpose deployment redis-server --address redis-server-c
skupper unexpose deployment redis-sentinel --address redis-sentinel-c