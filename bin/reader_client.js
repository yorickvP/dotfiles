#!/usr/bin/env node

var creds = require('/home/yorick/.config/googlecl/creds.json')

var https = require('https')
var querystring = require('querystring')
var GoogleClientLogin = require('googleclientlogin').GoogleClientLogin;
var googleAuth = new GoogleClientLogin({
  email: creds.user,
  password: creds.password,
  service: 'reader',
  accountType: creds.type
});


// thanks to http://code.google.com/p/pyrfeed/wiki/GoogleReaderAPI
function queryGoogleAPI(auth, apiname, method, parameters, cb) {
	var path = '/reader/api/0/' + apiname
	parameters.client = "yorickvp_reader_script/0.0.1"
	if (method == "GET")
		path += "?" + querystring.stringify(parameters)
	var request = https.request(
	  { host: 'www.google.com'
	  , path: path
	  , headers: 
	    { "Authorization": 'GoogleLogin auth=' + auth.getAuthId() }}
	, cb)
	if (method == "POST")
		request.end(querystring.stringify(parameters))
	else request.end() }

function getUnreadCounts(auth, cb) {
	queryGoogleAPI(auth, 'unread-count', "GET", {all: "false", output: 'json'}, function(res) {
		res.setEncoding('utf8')
		var dataAcc = ""
		res.on('data', function(d) { 
			dataAcc += d })
		res.on('end', function() {
			cb(JSON.parse(dataAcc)) })})}

function getTotalUnread(unreadcounts) {
	var uc = unreadcounts.unreadcounts
	if (!uc) return null
	var idre = /user\/[0-9]+\/state\/com\.google\/reading-list/
	for (var i = 0; i < uc.length; i++)
		if (idre.test(uc[i].id))
			return uc[i].count
	return 0 }

function getSubscriptions(auth, cb) {
	queryGoogleAPI(auth, 'subscription/list', "GET", {output: 'json'}, function(res) {
		res.setEncoding('utf8')
		var dataAcc = ""
		res.on('data', function(d) { 
			dataAcc += d })
		res.on('end', function() {
			cb(JSON.parse(dataAcc)) })})}

googleAuth.on('error', function(e) {
	console.log('error:', e) })

function usage() {
	console.log("usage:  reader_client.js [totalunread | unreadlist]")
	process.exit() }

function cmd_total_unread() {
	googleAuth.login()
	googleAuth.once('login', function() {
		getUnreadCounts(googleAuth, function(ucs) {
			process.stdout.write(getTotalUnread(ucs)+"\n") })})}

function strLimit(str, max) {
	return str.length > max ? str.slice(0, max - 2) + ".." : str }

function formatUnreadCountsNicely(ucs) {
	var res = ""
	return ucs
	   .map(function(uc) {
	   		var maxlen = 25
	   		if (!uc.title) return
	   		var firstPart = strLimit(uc.title, maxlen - 4) + ":"
	   		var lastPart = uc.count + ""
	   		var spaces = Array(maxlen - firstPart.length - lastPart.length).join(" ")
	   		return firstPart + spaces + lastPart })
	   .filter(function(ucstr) {
	   		return ucstr != undefined })
	   .join("\n")
}

function cmd_unread_list() {
	googleAuth.login()
	googleAuth.once('login', function() {
		// we need the subscriptions to find the titles
		getSubscriptions(googleAuth, function(subs) {
			var sub_table = {}
			subs.subscriptions.forEach(function(sub) {
				sub_table[sub.id] = sub })
			getUnreadCounts(googleAuth, function(ucs) {
				ucs = ucs.unreadcounts
				var labelre = /user\/[0-9]+\/label\/(.+)/
				ucs.forEach(function(uc) {
					var sub = sub_table[uc.id]
					if (sub) uc.title = sub.title
					else {
						var m = uc.id.match(labelre)
						if (m) uc.title = m[1] }})
				process.stdout.write(formatUnreadCountsNicely(ucs) + "\n")
			})
		})
	})
}

if (process.argv.length != 3) usage()
switch (process.argv[2]) {
	case "totalunread":
		cmd_total_unread()
		break
	case "unreadlist":
		cmd_unread_list()
		break
	default:
		usage()
}
