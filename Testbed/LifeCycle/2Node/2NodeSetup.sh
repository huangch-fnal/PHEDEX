#!/bin/bash
# Developer Testbed Setup - 2 node LoadTest

# This file describes the setup of a developer Testbed with a 2 node
# LoadTest.  This setup, when running, will create continuous activity
# for the transfer system.  Other PhEDEx components (deletions, block
# verification) are not tested under this setup, so other means must
# be used to test those.

# This file is written as a bash script but may not run correctly
# as-is.  The developer should understand what each of the commands
# here does and execute them "by hand".

# Compared to other software systems in CMS, PhEDEx is particularily
# difficult to test.  It requires a free database schema for the
# developer (or an organized method of sharing one), as well as a
# machine to run the agents.  This setup will run the logical aspects
# of the transfer management system however the actual interaction
# between PhEDEx and grid-transfer tools is not tested.  This setup is
# good for testing changes to transfer task allocation throughout all
# parts of the system, as well as library changes and other core
# behaviors (such as daemon running and event loops).

# The expected end result of this procedure is a fully deployed PhEDEx
# schema, central agents, and 2 site node agents which will transfer
# /LoadTestSink/LoadTestSink/$node datasets to each other at a fake
# rate of 100 MB/s for as long as these agents are running.

if [ -z $TESTBED_ROOT ]; then
  echo "TESTBED_ROOT not set, are you sure you sourced the environment?"
  exit 0
fi
if [ -z $LIFECYCLE ]; then
  echo "LIFECYCLE not set, are you sure you sourced the environment?"
  exit 0
fi
if [ -z $PHEDEX_ROOT ]; then
  echo "PHEDEX_ROOT not set, are you sure you sourced the environment?"
  exit 0
fi
if [ -z $PHEDEX_DBPARAM ]; then
  echo "PHEDEX_DBPARAM not set, are you sure you sourced the environment?"
  exit 0
fi

export PHEDEX=$PHEDEX_ROOT
PHEDEX_SQLPLUS="sqlplus $($PHEDEX/Utilities/OracleConnectId -db $PHEDEX_DBPARAM)"
PHEDEX_SQLPLUS_CLEAN=`echo $PHEDEX_SQLPLUS | sed -e's%/.*@%/password-here@%'`
# Minimal sanity-check on the DBPARAM and contents:
if [ `echo $PHEDEX_DBPARAM | egrep -ic 'prod|dev|debug|admin'` -gt 0 ]; then
  echo "Your DBParam appears to be unsafe?"
  echo "(It has one of 'prod|dev|debug|admin' in it, so I don't trust it)"
  exit 0
fi
if [ `echo $PHEDEX_SQLPLUS | egrep -ic 'devdb'` -eq 0 ]; then
  echo "Your DBParam appears to be unsafe?"
  echo "('devdb' does not appear in your connection string, so I don't trust it)"
  exit 0
fi

echo "Connection attempted as: $PHEDEX_SQLPLUS_CLEAN"
i=`echo 'select sysdate from dual;' | $PHEDEX_SQLPLUS 2>/dev/null | grep -c SYSDATE`
if [ $i -gt 0 ]; then
  echo "Your database connection is good..."
else
  echo "Cannot connect to your database (status=$i)"
  echo "Connection attempted as: $PHEDEX_SQLPLUS_CLEAN"
  echo "(your TNS_ADMIN is $TNS_ADMIN, in case that matters)"
  echo "(Oh, and your sqlplus is in `which sqlplus`)"
  exit 0
fi

# Create nodes / links
# T0 node (for central agents to run)
$PHEDEX_ROOT/Utilities/NodeNew -db $PHEDEX_DBPARAM -name T0_Test_MSS -kind MSS \
                         -technology Castor -se-name TAPE.srm-t0.nowhere.cern.ch
$PHEDEX_ROOT/Utilities/NodeNew -db $PHEDEX_DBPARAM -name T0_Test_Buffer -kind Buffer \
                         -technology Castor -se-name TAPE.srm-t0.nowhere.cern.ch
$PHEDEX_ROOT/Utilities/NodeNew -db $PHEDEX_DBPARAM -name T0_Test_Disk -kind Disk \
                         -technology Castor -se-name srm-t0.nowhere.cern.ch

# T0_Test node links
echo T0_Test_MSS to T0_Test_Buffer
$PHEDEX_ROOT/Utilities/LinkNew -db $PHEDEX_DBPARAM T0_Test_MSS T0_Test_Buffer:L/1 
# N.B. This next line sets priorities both ways to L/1. It should really be
# L/1 from Buffer to Disk and L/4 from Disk to Buffer
echo T0_Test_Disk to T0_Test_Buffer
$PHEDEX_ROOT/Utilities/LinkNew -db $PHEDEX_DBPARAM T0_Test_Disk T0_Test_Buffer:L/1 

# Create one T1_Test node
$PHEDEX_ROOT/Utilities/NodeNew -db $PHEDEX_DBPARAM -name T1_Test1_MSS -kind MSS\
			-technology Other -se-name TAPE.srm-test1.nowhere.cern.ch
$PHEDEX_ROOT/Utilities/NodeNew -db $PHEDEX_DBPARAM -name T1_Test1_Buffer -kind Buffer \
			-technology Other -se-name TAPE.srm-test1.nowhere.cern.ch
$PHEDEX_ROOT/Utilities/NodeNew -db $PHEDEX_DBPARAM -name T1_Test1_Disk -kind Disk \
                         -technology Other -se-name srm-test1.nowhere.cern.ch

# T1_Test1 node links
echo T1_Test1_MSS to T1_Test1_Buffer
$PHEDEX_ROOT/Utilities/LinkNew -db $PHEDEX_DBPARAM T1_Test1_MSS T1_Test1_Buffer:L/1 
# N.B. This next line sets priorities both ways to L/1. It should really be
# L/1 from Buffer to Disk and L/4 from Disk to Buffer
echo T1_Test1_Disk to T1_Test1_Buffer
$PHEDEX_ROOT/Utilities/LinkNew -db $PHEDEX_DBPARAM T1_Test1_Disk T1_Test1_Buffer:L/1 

# T1_Test1 to T0_Test links
echo T1_Test1_Buffer to T0_Test_Buffer
$PHEDEX_ROOT/Utilities/LinkNew -db $PHEDEX_DBPARAM T0_Test_Buffer T1_Test1_Buffer:R/4
echo T1_Test1_Disk to T0_Test_Disk
$PHEDEX_ROOT/Utilities/LinkNew -db $PHEDEX_DBPARAM T0_Test_Disk T1_Test1_Disk:R/1

# N.B. This next line sets priorities both ways to L/1. It should really be
# L/1 from Buffer to Disk and L/4 from Disk to Buffer
echo T1_Test1_Disk to T0_Test_Buffer
$PHEDEX_ROOT/Utilities/LinkNew -db $PHEDEX_DBPARAM T0_Test_Buffer T1_Test1_Disk:R/1
echo T1_Test1_Buffer to T0_Test_Disk
$PHEDEX_ROOT/Utilities/LinkNew -db $PHEDEX_DBPARAM T0_Test_Disk T1_Test1_Buffer:R/1

i=1
echo -n "Inserting groups: "
for group in physicists managers operators administrators experts other
do
  echo -n "$group "
  echo "insert into t_adm_group (id,name) values ($i,'$group');" | $PHEDEX_SQLPLUS >/dev/null
  i=`expr $i + 1`
done
echo "groups inserted"

cd $LIFECYCLE/2Node/
../getNodesGroups.sh
echo 2-node setup completed
