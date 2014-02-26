
util = require 'util'
readline = require 'readline'
fs = require 'fs'
{join} = require 'path'
require 'shelljs/global'

evaluator = require './evaluator'

historyFile = join process.env.HOME, '.cirru_history'

completer = (line) ->
  if line[line.length - 1] is '('
    # console.log shell.line, shell.cursor
    if shell.line[shell.cursor] isnt ')'
      setTimeout ->
        shell._moveCursor -1
      , 0
      return [['()'], '(']
    else
      return []
  matchLastWord = line.match(/[\w-:\/]+$/)
  return [evaluator.candidates, ''] unless matchLastWord?
  lastWord = matchLastWord[0]
  wordsBefore = line[...(-lastWord.length)]
  # console.log "(#{lastWord})"
  # console.log 'before:', wordsBefore
  hits = evaluator.candidates
  .filter (word) ->
    (word.indexOf lastWord) is 0
  if hits.length > 0
    # console.log [hits, line]
    [hits, lastWord]
  else
    []

shell = readline.createInterface
  input: process.stdin
  output: process.stdout
  completer: completer

if fs.existsSync historyFile
  (JSON.parse (cat historyFile)).forEach (command) ->
    shell.history.push command
else
  '[]'.to historyFile

shell.setPrompt 'cirru> '
shell.prompt()

shell.on 'line', (anwser) ->
  # console.log (Object.keys shell)
  # console.log (Object.keys shell.__proto__)
  try
    resultString = evaluator.call null, anwser
    util.print '=> '
    console.log resultString
  catch error
    console.log error
  console.log ''
  shell.prompt()

shell.on 'SIGINT', ->
  process.exit()

process.on 'exit', ->
  # console.log 'history', shell.history, 'to', historyFile
  (JSON.stringify shell.history, null, 2).to historyFile