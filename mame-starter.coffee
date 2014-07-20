fs = require "fs"
util = require 'util'#console.log(util.inspect(res, false, null))
spawn = require("child_process").spawn
colors = require('colors')
parseString = require("xml2js").parseString
keypress = require "keypress"
cols = process.stdout.columns
rows = process.stdout.rows
romPath = __dirname+"/../roms/"
games = []
selGame = ""
menuOffset = 0
keyInit = false
whileInitScreen = false


console.log "Welcome to MAME starter"
# get args
getReloadArg= ->
  reload = false
  process.argv.forEach (val, index, array) -> if val is "-r" then return reload= true
  reload

checkGamelist= (cb, cb2)->
  exists = true
  fs.readFile romPath+"games.txt", (err, res)->
    if err
      console.log("no games.txt found")
      cb(cb2)
    else
      console.log "games.txt found"
      games = JSON.parse res
      cb2()

# change ros,colums on console size
process.stdout.on "resize", ->
  cols = process.stdout.columns
  rows = process.stdout.rows
  if whileInitScreen is false then initSelectSreen()

startGame = ->
  grep = spawn("mame", [selGame, "-rol", "-rompath", romPath])
  grep.on "close", -> initSelectSreen()


getGoodGames= (cb)->
  writeFile = ->
    data = JSON.stringify games
    console.log data
    fs.writeFile romPath+"games.txt", data, (err)-> if !err then cb()
  getGameXml= (game, cb)->
    rawXml = ""
    mameGetXml = spawn("mame", ["-listxml", game])
    mameGetXml.stdout.on 'data', (data)->
      rawXml += data#.toString()
    mameGetXml.on 'close', (code)->
      parseString rawXml, (err, result)->
        if err then throw err
        obj = 
          file: game
          name: result.mame.game[0].description+" - "+result.mame.game[0].manufacturer+" - "+result.mame.game[0].year
        console.log(obj.name)
        games.push obj

  ### ASYNC PROBLEM ??? ###
  console.log("search for goodgames in rompath")
  mameCheck = spawn("mame", ["-verifyroms", "-rompath", romPath])
  mameCheck.stdout.on 'data', (data)->
    #for key,val of data then console.log(key,val)
    res = data.toString().split(" ")
    if res[0] is "romset" && res[3] is "good\n"
      getGameXml res[1]


  mameCheck.on 'close', (code)->
    console.log("get good games finished!")
    writeFile()

initKeys= ->
  keypress(process.stdin);
  process.stdin.setRawMode(true)
  process.stdin.resume()
  process.stdin.on "keypress", (ch, key) ->
    #console.log("key pressed: ", key)
    #process.stdin.pause()  if key and key.ctrl and key.name is "c"
    if key.name=="s"
      menuOffset--
      if menuOffset<0 then menuOffset = games.length
      initSelectSreen()
    else if key.name=="w"
      #menuOffset++
      if ++menuOffset>games.length then menuOffset=0
    else if key.name=="return"
      #menuOffset++
      startGame()
    else return
    initSelectSreen()

# main menu screen
initSelectSreen= ->
  whileInitScreen = true
  if keyInit is false then initKeys(); keyInit = true
  len = rows-1
  while len--
    g = games[(len+menuOffset)%games.length]
    result = ""
    space = ""
    spaceL = ""
    spacelen = Math.round((cols-g.name.length)/2)
    spacelenL = cols-spacelen-g.name.length
    while spacelen-- then space += " "
    while spacelenL-- then spaceL += " "
    if len is ~~(rows/2)
      name = g.name
      result += (space.blackBG+name.blackBG.white+spaceL.blackBG)
      selGame = g.file
    else result += (space+g.name)
    console.log(result)
  whileInitScreen = false

## init app
if getReloadArg is true then getGoodGames initSelectSreen
else checkGamelist getGoodGames, initSelectSreen
#getGamesAsync(x)

#getGoodGames(initSelectSreen)
