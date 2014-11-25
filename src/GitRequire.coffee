async = require 'async'
fs = require 'fs'
path = require 'path'
{exec, spawn} = require 'child_process'

module.exports = class GitRequire
  constructor: (@projectDir, @action='install') ->

  start: (cb) ->
    @readConfig (err) =>
      return cb err if err
      @performAction cb

  readConfig: (cb) ->
    file = path.join @projectDir, 'git-require.json'
    fs.readFile file, {encoding: 'utf8'}, (err, data) =>
      return cb err if err
      try
        @config = JSON.parse data
      catch
        return cb 'failed-to-parse-json'
      cb()

  performAction: (cb) ->
    fn = @['action_' + @action]
    return cb 'no-such-action' unless fn
    fn.bind(@) cb

  action_install: (cb) ->
    repos = []
    for name, data of @config.repos
      repos.push [name, data]
    repos.sort()
    async.mapSeries repos, @installRepo.bind(@), cb

  installRepo: (repo, cb) ->
    dir = path.join @projectDir, @config.dir, repo[0]
    fs.exists dir, (exists) =>
      if exists
        @updateRepo dir, repo[1], cb
      else
        @cloneRepo dir, repo[1], cb

  updateRepo: (dir, url, cb) ->
    console.log 'Updating', url, 'into', dir
    exec """
      cd '#{dir}'
      git pull
    """, cb

  cloneRepo: (dir, url, cb) ->
    console.log 'Cloning', url, 'in', dir
    run 'git', ['clone', url, dir], cb

run = (name, args, cb) ->
  p = spawn name, args
  p.stdout.on 'data', (data) -> process.stdout.write data
  p.stderr.on 'data', (data) -> process.stderr.write data
  p.on 'close', (code) ->
    return cb 'code-' + code unless code is 0
    cb()
