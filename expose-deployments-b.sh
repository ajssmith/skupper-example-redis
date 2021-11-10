#!/bin/bash
skupper expose deployment redis-server --address redis-server-b
skupper expose deployment redis-sentinel --address redis-sentinel-b