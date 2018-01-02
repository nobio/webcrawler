#!/bin/bash

rm -f ./crawl/crawldb/.locked 
rm -f ./crawl/crawldb/..locked.crc 

# if no args specified, show usage
if [ $# = 0 ]; then
    echo "Usage: run-crawler [-c <solr core>] [-r <rounds>]"
    echo "        -c solr core        name of solr core"
    echo "        -r rounds           number of crawl cycles"
    exit 1
fi

# get arguments

while [[ $# > 0 ]]
do
    case $1 in
        -c)
            CORE=${2}
            shift 2
            ;;
        -r)
            ROUNDS=${2}
            shift
            ;;
        *)
            break
            ;;
    esac
done

echo solr core to be generated/used: $CORE
echo numbers of crawl cycles: $ROUNDS
echo inject seeds
./bin/nutch inject crawl/crawldb seeds

# loop -------------------------------------------
for i in {1..5}
do
    echo "============================ ROUND $i ==============================="

    echo crawl 
    #./bin/nutch generate crawl/crawldb crawl/segments  -topN 100
    ./bin/nutch generate crawl/crawldb crawl/segments
    export s1=`ls -d crawl/segments/2* | tail -1`

    echo fetch $s1
    ./bin/nutch fetch $s1 -all

    echo parse $s1
    ./bin/nutch parse $s1 -all

    echo update db $s1
    ./bin/nutch updatedb crawl/crawldb $s1
done
# loop end----------------------------------------

echo invert links
./bin/nutch invertlinks crawl/linkdb -dir crawl/segments

echo create new core
../solr-6.6.2/bin/solr create -c $CORE

echo create index 
#./bin/nutch index -Dsolr.server.url=http://localhost:8983/solr/consorsbank crawl/crawldb/ -linkdb crawl/linkdb/ crawl/segments/ -dir $s1 -filter -normalize
#./bin/nutch solrindex http://localhost:8983/solr/consorsbank3 crawl/crawldb/ -linkdb crawl/linkdb/ $s1 -filter -normalize -deleteGone
./bin/nutch solrindex http://localhost:8983/solr/$CORE crawl/crawldb/ -linkdb crawl/linkdb/ crawl/segments/* -filter -normalize -deleteGone

#das gleiche wie 
#./bin/nutch solrindex http://localhost:8983/solr/consorsbank crawl/crawldb/ -linkdb crawl/linkdb/ crawl/segments/20171229143124 -filter -normalize

