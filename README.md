Nutch und Solr
==============

Versionen
----------
### 1. Solr ###
Solr wird in der Version 6.6.2 verwendet
http://archive.apache.org/dist/lucene/solr/6.6.2/

### 2. Apache Nutch ###
Apache Nutch wird in der Version 1.14 verwendet. Die 1.* - Version gibt es als Binaries, die 2.* nur als Source, die mit ant gebaut werden müssen.
http://www.apache.org/dyn/closer.lua/nutch/1.14/apache-nutch-1.14-src.zip


Vorbereitung
--------------
<ul>
<li> seed: Verzeichnis "seeds" anlegen (<code>$NUTCH_HOME/seeds</code>) und dort eine Datei <code>seeds.txt</code> hinterlegen. Diese Datei enthält die Einsprungadressen, die vom Crawler besucht werden. </li>

<li> <code>nutch-site.xml</code>: Die Datei $NUTCH_HOME/conf/nutch-site.xml anpassen: 
<code>

    <configuration>    
        <property>
           <name>http.agent.name<name>
           <value>Nobios Web Crawler<value>
        <property>
    <configuration>

</code>

</li>

<li>
Die Datei <code>$NUTCH_HOME/conf/regex-urlfilter.txt</code> kann angepasst werden. Diese Datei dient dazu, den Crawler auf bestimmte domains einzuschränken. Folgende Zeile ist per Default enthalten:

<code>

    # accept anything else
    +.

</code>

und kann durch folgende ersetzt werden, um auf die Domain 'consorsbank.de' einzuschränken:

<code>

    # accept only *.consorsbank.de/*
    #+^http[s]?:\/\/[a-z]{0,20}\.consorsbank\.de

</code>
</li>

<li>
Starten von solr:
<code>$SOLR_HOME/bin/solr start -f</code>
(-f: Foreground)
</li>

</ul>

Start Crawler
--------------
Um den Crawler zu starten kann man nach diversen Tutorials vorgehen oder das skript 
    run-crawler.sh
verwenden. Vorher sollte der Ordner <code>crawl</code> komplett gelöscht werden, da ansonsten die Ergebnisse der vorläufer-Crawls mit übernommen weden.
    
    rm -rf $NUTCH_HOME/crawl

Das Skript übernimmt den Core-Namen als Parameter und legt in Solr einen neuen Core an. Nach 5 Runden (ACHTUNG: Eine Runde reicht nicht, man muss mehrere Runden durchlaufen, da ansonsten fast nichts gefunden wird. Warum, weiß ich auch nicht...) 

run-crawler.sh
--------------

```{r, engine='bash'}
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

```
