GitRequire = require './GitRequire'

module.exports =
  GitRequire: GitRequire

  install: (projectDir, config, cb) ->
    init projectDir, config, (err, gitRequire) ->
      return cb err if err
      gitRequire.action 'install', (err) ->
        return cb err if err
        cb null, gitRequire.repos

  repos: (projectDir, config, cb) ->
    init projectDir, config, (err, gitRequire) ->
      return cb err if err
      cb null, gitRequire.repos

init = (projectDir, config, cb) ->
  gitRequire = new GitRequire projectDir, config
  gitRequire.init (err) ->
    return cb err if err
    cb null, gitRequire
