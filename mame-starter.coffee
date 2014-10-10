fs = require "fs"
util = require 'util'#console.log(util.inspect(res, false, null))
spawn = require("child_process").spawn
colors = require('colors')
parseString = require("xml2js").parseString
keypress = require "keypress"
cols = process.stdout.columns
rows = process.stdout.rows
romPath = __dirname+"/roms/"
configPath = __dirname+"/config/"
keys =
  up: "w"
  down: "s"
  submit: "return"
games = []
selGame = ""
menuOffset = 0
keyInit = false
whileInitScreen = false
rotateScreenBool = false


console.log "Welcome to MAME starter"
# get args
getArgs= ->
  reload = false
  process.argv.forEach (val, index, array) ->
    if val is "-r" then reload= true
    if val.slice(0, 2) is "./" or val.slice(0, 3) is "../"
      romPath = __dirname+"/"+val+"/"
  reload

checkGamelist= (cb, cb2)->
  exists = true
  fs.readFile configPath+"games.txt", (err, res)->
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
  if whileInitScreen is false then renderSelectScreen()

startGame = ->
  if rotateScreenBool is true
    rotateScreen("normal")
    grep = spawn("mame", [selGame, "-rol", "-rompath", romPath, "-cfg_directory", configPath])
  else grep = spawn("mame", [selGame, "-rompath", romPath, "-cfg_directory", configPath])
  grep.on "close", -> renderSelectScreen()


getGoodGames= (cb)->
  writeFile = ->
    data = JSON.stringify games
    console.log data
    fs.writeFile configPath+"games.txt", data, (err)-> if !err then cb()
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
  console.log("search for goodgames in rompath", romPath.white)
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
    if whileInitScreen is true then return
    if key.name==keys.down
      menuOffset--
      if menuOffset<0 then menuOffset = games.length
      renderSelectScreen()
    else if key.name==keys.up
      #menuOffset++
      if ++menuOffset>games.length then menuOffset=0
    else if key.name==keys.submit
      #menuOffset++
      startGame()
    if key && key.name is "c" && key.ctrl 
      console.log("bye bye!")
      process.exit()

    renderSelectScreen()

rotateScreen= (orientation)-> grep = spawn("xrandr", ["-o", orientation])

writeConfig = ->
  data = JSON.stringify games
  console.log data
  fs.writeFile configPath+"default.cfg", data, (err)-> if !err then cb()

# main menu screen
renderSelectScreen= ->
  whileInitScreen = true
  if keyInit is false then initKeys(); keyInit = true
  process.stdout.write("\u001B[2J\u001B[0;0f")
  fixedRows = 13
  rowsleft = ~~((rows-fixedRows)/2)
  while rowsleft-- then process.stdout.write "\n"
  len = Math.round(fixedRows-1)
  while len--
    g = games[(len+menuOffset)%games.length]
    result = ""
    space = ""
    spaceL = ""
    spacelen = Math.round((cols-g.name.length)/2)
    spacelenL = Math.round(cols-spacelen-g.name.length)
    if spacelen>1 then while spacelen-- then space += " "
    if spacelenL>1 then while spacelenL-- then spaceL += " "
    
    if len is ~~(fixedRows/2)
      name = g.name
      result += (space.blackBG+name.blackBG.white+spaceL.blackBG)
      selGame = g.file
    else result += (space+g.name)
    process.stdout.write(result+"\n")
  setTimeout (->whileInitScreen = false), 280


## INIT APP
###########
if rotateScreenBool is true then rotateScreen("left")
if getArgs() is true then getGoodGames renderSelectScreen
else checkGamelist getGoodGames, renderSelectScreen
#getGoodGames(renderSelectScreen)
