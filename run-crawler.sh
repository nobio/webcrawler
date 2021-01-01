#!/bin/bash
unset URL
unset CORE
unset SOLR_HOME
unset NUTCH_HOME
export SOLR_HOME=/opt/solr
export NUTCH_HOME=/opt/nutch

# if no args specified, show usage
if [ $# = 0 ]; then
    echo "Usage: run-crawler [-c <solr core>] [-r <rounds>] [-u <url to crawl>] [-b <build new>]"
    echo "  -c solr core        name of solr core"
    echo "  -r rounds           number of crawl cycles"
    echo "  -u url              url to crawl (goes to seed.txt)"
    echo "  -b true/false       flag that indicates if the core should be created from cratch or not (default=false)"
    exit 1
fi

# get arguments
BUILD_NEW=false
while [[ $# > 0 ]]
do
    case $1 in
        -c)
            CORE=${2}
            shift 2
            ;;
        -r)
            ROUNDS=${2}
            shift 2
            ;;
        -u)
            URL=${2}
            shift 2
            ;;
        -b)
            BUILD_NEW=${2}
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# ************************************************************************************


echo " -----------------------------------------------------------"
echo "   solr core to be generated/used: $CORE"
echo "   numbers of crawl cycles:        $ROUNDS"
echo "   url to start crawling:          $URL"
echo "   build new core:                 $BUILD_NEW"
echo " -----------------------------------------------------------"
if [[ "$BUILD_NEW" == "true" ]]
then
    curl http://localhost:8983/solr/$CORE/update --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
    curl http://localhost:8983/solr/$CORE/update --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
    sudo rm -rf $NUTCH_HOME/logs/ $NUTCH_HOME/crawl/ $NUTCH_HOME/tmp $SOLR_HOME/server/solr/configsets/$CORE/

    sudo mkdir -p $SOLR_HOME/server/solr/configsets/$CORE/
    sudo cp -r $SOLR_HOME/server/solr/configsets/_default/* $SOLR_HOME/server/solr/configsets/$CORE/

    mkdir -p $NUTCH_HOME/tmp
    curl https://raw.githubusercontent.com/apache/nutch/master/src/plugin/indexer-solr/schema.xml > $NUTCH_HOME/tmp/schema.xml
    sudo mv $NUTCH_HOME/tmp/schema.xml $SOLR_HOME/server/solr/configsets/$CORE/conf/
    mkdir -p $NUTCH_HOME/urls
    echo $URL > $NUTCH_HOME/urls/seed.txt

    sudo -u solr $SOLR_HOME/bin/solr create -c $CORE -d $SOLR_HOME/server/solr/configsets/$CORE/conf/
fi

# finally start crawling
echo " ------------------------------------------------------------------------------------------------------"
echo start crawling: 
echo $NUTCH_HOME/bin/crawl -i -s $NUTCH_HOME/urls/ $NUTCH_HOME/crawl/ $ROUNDS
echo " ------------------------------------------------------------------------------------------------------"
$NUTCH_HOME/bin/crawl -i -s $NUTCH_HOME/urls/ $NUTCH_HOME/crawl/ $ROUNDS