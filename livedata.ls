require! <[fs]>

files = (fs.readdir-sync \data).map(-> "data/#it")sort!reverse!
files = files[0 to 89]
hash = {}
for file in files
  date = file.replace "data/", ""
  data = JSON.parse(fs.read-file-sync file .toString!)
  for k,v of data =>
    if !hash[k] => hash[k] = {}
    v = {c: v.capacity, r: v.rainfall, i: v.income, o: v.output, l: v.level, v: v.volume, p: v.percent}
    hash[k][date] = v
fs.write-file-sync \live.json, JSON.stringify(hash)
