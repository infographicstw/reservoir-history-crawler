require! <[fs cheerio request bluebird]>

dmap = {1: 31, 2: 29, 3: 31, 4: 30, 5: 31, 6: 30, 7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31}

init = -> new bluebird (res, rej) ->
  (e,r,b) <- request {
    url: \http://fhy.wra.gov.tw/ReservoirPage_2011/StorageCapacity.aspx
    method: \GET
  }, _
  if e or !b => return rej!
  $ = cheerio.load b.toString!
  params = {}
  for item in $("input")
    params[$(item).attr("name")] = $(item).attr("value")
  params <<< do
    "ctl00$cphMain$cboSearch": "所有水庫"
    "ctl00$cphMain$ucDate$cboYear": 2003 # 1970 ~ 2015 (2003.1.1)
    "ctl00$cphMain$ucDate$cboMonth":  1  # 1 ~ 12
    "ctl00$cphMain$ucDate$cboDay":    1  # 1 ~ 31
  res params

setparam = (y,m,d,params)->
  params <<< do
    "ctl00$cphMain$ucDate$cboYear":  y
    "ctl00$cphMain$ucDate$cboMonth": m
    "ctl00$cphMain$ucDate$cboDay":   d

toValue = (v) ->
  v = v.replace(/[%,]/g,"").trim!
  u = parseFloat(v)
  if isNaN(u) => return -1
  return u

parse = (data) ->
  $ = cheerio.load data
  entries = $('#cphMain_gvList tr')
  hash = {}
  for item in entries
    item = $(item)
    name = item.find("td:nth-of-type(1)").text!trim!
    if name.length <=1 or name.length > 10 => continue
    if /附註/.exec name => continue
    capacity = toValue(item.find("td:nth-of-type(2)").text!)
    rainfall = toValue(item.find("td:nth-of-type(4)").text!)
    income = toValue(item.find("td:nth-of-type(5)").text!)
    output = toValue(item.find("td:nth-of-type(6)").text!)
    level = toValue(item.find("td:nth-of-type(10)").text!)
    volume = toValue(item.find("td:nth-of-type(11)").text!)
    percent = toValue(item.find("td:nth-of-type(12)").text!)
    obj = { name, capacity, rainfall, income, output, level, volume, percent }
    hash[name] = obj
  return hash

pad = (v,len=2)->
  clen = "#v".length
  if clen < len => return "0"*(len - clen) + "#v"
  return "#v"
  if "#v".length < len =>

_fetch = (y,m,d,params) -> new bluebird (res, rej) ->
  if fs.exists-sync "data/#{pad(y,4)}-#{pad(m,2)}-#{pad(d,2)}" => return res!
  console.log y,m,d
  setparam y,m,d,params
  #console.log params{"ctl00$cphMain$ucDate$cboYear","ctl00$cphMain$ucDate$cboMonth","ctl00$cphMain$ucDate$cboDay"}

  (e,r,b) <- request {
    url: \http://fhy.wra.gov.tw/ReservoirPage_2011/StorageCapacity.aspx
    method: \POST
    form: params
    #body: [encodeURIComponent("#k=#v") for k,v of params].join(\&)
  }, _
  if e or !b => return rej!
  ret = parse b.toString!
  outfile = "data/#{pad(y,4)}-#{pad(m,2)}-#{pad(d,2)}"
  fs.write-file-sync outfile, JSON.stringify(ret)
  return res ret

next = (y,m,d) ->
  d++
  if dmap[m] < d => 
    d = 1
    m++
  if m > 12 =>
    m = 1
    y++
  return [y,m,d]

fetch = (y,m,d,params) ->
  _fetch y,m,d,params .then ->
    [y,m,d] := next y,m,d
    if new Date!getTime! <= new Date(y,m - 1,d).getTime! => return
    else fetch y,m,d,params

(params) <- init!then

fetch 2003,1,2,params
