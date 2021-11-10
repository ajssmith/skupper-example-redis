#!/bin/bash
skupper unexpose deployment redis-server --address redis-server-b
skupper unexpose deployment redis-sentinel --address redis-sentinel-b