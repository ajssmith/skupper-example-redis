#!/bin/bash
skupper expose deployment redis-server --address redis-server-a
skupper expose deployment redis-sentinel --address redis-sentinel-a