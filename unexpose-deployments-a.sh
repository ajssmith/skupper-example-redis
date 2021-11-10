#!/bin/bash
skupper unexpose deployment redis-server --address redis-server-a
skupper unexpose deployment redis-sentinel --address redis-sentinel-a