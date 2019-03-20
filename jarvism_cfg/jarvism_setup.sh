#!/bin/bash
export JVS_PRJ_HOME=$PWD
export JVS_WORK_DIR=$JVS_PRJ_HOME/work

if [ -z $JVSUK_HOME ]
then
export JVSUK_HOME=$JVS_PRJ_HOME
fi