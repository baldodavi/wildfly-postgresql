#!/bin/bash
chmod -R 777 JBOSS_HOME/standalone
$JBOSS_HOME/bin/standalone.sh -b=0.0.0.0 -bmanagement=0.0.0.0

