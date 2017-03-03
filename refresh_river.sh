#!/bin/bash

# Script to refresh index and force reindex
# These variables needs to be seet:
# export DCP_URL=https://dcp.stage.jboss.org
# export DCP_USER=jbossorg
# export DCP_PASS=
# Usage: ./refresh_river.sh stackoverflow_question

[[ -z "$1" ]] && { echo -e "Name of indexer not set."; echo -e "Usage: ./refresh_river.sh stackoverflow_question"; exit 1; }

[[ -z "$DCP_URL" ]] && { echo "Variable DCP_URL is not set"; exit 1; }
[[ -z "$DCP_USER" ]] && { echo "Variable DCP_USER is not set"; exit 1; }
[[ -z "$DCP_PASS" ]] && { echo "Variable DCP_PASS is not set"; exit 1; }

INDEXER_NAME=$1

echo -e ==== REFRESH $INDEXER_NAME INDEXER ====

echo -e ==== Stop Indexer ====
curl -u $DCP_USER:$DCP_PASS -X POST $DCP_URL/v2/rest/indexer/$INDEXER_NAME/_stop

echo -e ; echo -e ==== Delete Index ====
curl -u $DCP_USER:$DCP_PASS -X DELETE $DCP_URL/v2/rest/sys/es/search/data_$INDEXER_NAME

echo -e ; echo -e ==== Create Index ====
cd indexes
sh init_index.sh data_$INDEXER_NAME.json $DCP_URL/v2/rest/sys/es/search $DCP_USER $DCP_PASS
cd ..

echo -e ==== Push new mapping ====
cd mappings
sh init_mapping.sh data_$INDEXER_NAME/$INDEXER_NAME.json $DCP_URL/v2/rest/sys/es/search $DCP_USER $DCP_PASS
cd ..

echo -e ==== Push new indexer config ====
cd rivers
sh init_river.sh $INDEXER_NAME.json $DCP_URL/v2/rest/sys/es/search $DCP_USER $DCP_PASS
cd ..

echo -e ==== Restart indexer ====
curl -u $DCP_USER:$DCP_PASS -X POST $DCP_URL/v2/rest/indexer/$INDEXER_NAME/_restart
echo -e; echo -e ==== Force reindex ====
curl -u $DCP_USER:$DCP_PASS -X POST $DCP_URL/v2/rest/indexer/$INDEXER_NAME/_force_reindex

echo -e; echo -e ==== DONE ====