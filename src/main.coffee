optimist = require 'optimist'
path = require 'path'
GitRequire = require './GitRequire'

module.exports = main = ->
  argv = optimist
  .usage 'Usage: $0'

  .default 'p', path.resolve '.'
  .alias 'p', 'project-dir'
  .describe 'p', 'The location of the project (contains `git-require.json`).'

  .default 'a', 'install'
  .alias 'a', 'action'
  .describe 'a', 'Which action to perform: install, list.'

  .alias 'h', 'help'
  .describe 'h', 'Print this help message.'
  .argv

  cb = (err) -> throw err if err

  return optimist.showHelp() if argv.h

  gitRequire = new GitRequire argv['project-dir']
  gitRequire.init (err) ->
    return cb err if err
    gitRequire.action argv.action, cb
