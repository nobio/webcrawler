const express = require('express');
const app = express();
const server = require('http').createServer(app);
const request = require('request');
const BASE_URL = 'http://ubuntu20:8983/solr';
const URL = 'http://localhost:8983/solr/consorsbank03/select?wt=json&rows=100&q='

app.set('views', __dirname + '/views');
app.use(express.static(__dirname + '/JS'));
app.set('view engine', 'ejs');
app.engine('html', require('ejs').renderFile);

app.get('/', function (req, res) {
  res.render('search.html');
});

app.get('/search', function (req, res) {
  const queryURI = encodeURI(BASE_URL + '/' + req.query.core + '/select?wt=json&rows=100&q=content:' + req.query.key + '');
  //console.log(queryURI);

  request(queryURI, function (error, response, body) {
    if (error) {
      res.status(500).send(error);
      return;
    }


    var r = JSON.parse(body);
    var responseList = [];

    if (r.response) {
      console.log(`Treffer: ${r.response.numFound}, Docs: ${r.response.docs.length}`);
      r.response.docs.forEach(element => {
        if (element.title && element.url) {
          responseList.push(
            {
              title: element.title,
              url: encodeURI(element.url),
              //content:element.content,
            }
          );
        }
      });
    }
    //console.log(responseList);
    res.status(200).send(responseList);
  });

});

app.listen(3000, function () {
  console.log("Server started on port 3000.\nMake sure to unset http(s)_proxy:\n  unset http_proxy\n  unset https_proxy");
});
