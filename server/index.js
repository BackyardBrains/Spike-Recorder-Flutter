const express = require('express');
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
// var admin = require("firebase-admin");


// admin.initializeApp({
//     credential: admin.credential.applicationDefault
// });
const app = express();

app.use((req,res,next)=>{
    res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    next();
});

app.use(express.static(process.cwd()+'/pub'));

app.get('/', function(req,res) {
    res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    res.sendFile('index.html', { root: __dirname+"/pub"});
});


app.get('/Prototype1', function(req,res) {
    res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    res.sendFile('index.html', { root: __dirname+"/pub/Prototype1"});
});


app.get('/Prototype2', function(req,res) {
    res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    res.sendFile('index.html', { root: __dirname+"/pub/Prototype2"});
});

exports.app = onRequest(app);