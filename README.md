Nutch und Solr
==============

Versionen
----------
### 1. Solr ###
Solr wird in der Version 8.5.1 (oder 7.3.1) verwendet
`wget http://archive.apache.org/dist/lucene/solr/8.5.1/solr-8.5.1.tgz`

### 2. Apache Nutch ###
Apache Nutch wird in der Version 1.17 (oder 1.16) verwendet. 
`wget http://archive.apache.org/dist/nutch/1.17/apache-nutch-1.17-bin.tar.gz`


### 3. Search Bar
Zum Durchsuchen von Solr dient eine kleine Node-Anwendung (searchbar). Diese bindet sich auf Port 3000 und ruft intern den lokalen Solr Server auf,

Installation
--------------
```
wget http://archive.apache.org/dist/lucene/solr/8.5.1/solr-8.5.1.tgz
wget http://archive.apache.org/dist/nutch/1.17/apache-nutch-1.17-bin.tar.gz

tar xvf solr-7.3.1.tgz
tar vfx apache-nutch-1.16-bin.tar.gz

sudo mv apache-nutch-1.16 /opt/
sudo ln -s /opt/apache-nutch-1.16 /opt/nutch
sudo ./solr-7.3.1/bin/install_solr_service.sh ./solr-7.3.1.tgz
sudo systemctl enable solr solr.service

vi /opt/nutch/conf/nutch-site.xml
(hinzufügen:)
    ------------
    <configuration>    
        <property>
           <name>http.agent.name<name>
           <value>Nobios Web Crawler<value>
        <property>
    <configuration>
    ------------

sudo vi /etc/profile
    ------------
    export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
    export NUTCH_HOME=/opt/nutch
    export SOLR_HOME=/opt/solr
    ------------

vi conf/nutch-default.xml 
    ------------
    <property>
      <name>fetcher.server.delay</name>
      <value>1.0</value>
    ...
    ------------
```

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
Starten von solr: Einrichtung Service: `systemct solr`
</li>

</ul>

Start Crawler
--------------
Um den Crawler zu starten kann man nach diversen Tutorials vorgehen oder das skript 
    run-crawler.sh

Das Skript übernimmt den Core-Namen als Parameter und legt in Solr einen neuen Core an. Nach 5 Runden (ACHTUNG: Eine Runde reicht nicht, man muss mehrere Runden durchlaufen, da ansonsten fast nichts gefunden wird. Warum, weiß ich auch nicht...) 

run-crawler.sh
--------------
```
Usage: run-crawler [-c <solr core>] [-r <rounds>] [-u <url to crawl>] [-b <build new>]
  -c solr core        name of solr core
  -r rounds           number of crawl cycles
  -u url              url to crawl (goes to seed.txt)
  -b true/false       flag that indicates if the core should be created from cratch or not (default=false)
```
```bash
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

```
