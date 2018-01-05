const express = require('express');
const app = express();
const server = require('http').createServer(app);
const request = require('request');
const URL = 'http://localhost:8983/solr/consorsbank.de/select?wt=json&rows=100&q='

app.set('views', __dirname + '/views');
app.use(express.static(__dirname + '/JS'));
app.set('view engine', 'ejs');
app.engine('html', require('ejs').renderFile);

app.get('/', function (req, res) {
  res.render('search.html');
});

app.get('/search', function (req, res) {
  var queryURI = encodeURI(URL + req.query.key);
  console.log(queryURI);

  request(queryURI, function (error, response, body) {
    if (error) {
      console.log(error);
//      res.status(error.statusCode).send(error);
      res.status(500).send(error);
      return;
    }


    var r = JSON.parse(body);
    var responseList = [];

    console.log(r.response.numFound);
    if (r.response) {
      r.response.docs.forEach(element => {
        if (element.title && element.url) {
          responseList.push(
            { title: element.title[0], url: encodeURI(element.url[0]) }
          );
        }
      });
    }
    console.log(responseList);
    res.status(200).send(responseList);
  });

});

app.listen(3000, function () {
  console.log("Server started on port 3000.\nMake sure to unset http(s)_proxy:\nunset http_proxy\nunset https_proxy");
});
