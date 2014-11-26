async = require 'async'
fs = require 'fs'
path = require 'path'
{exec, spawn} = require 'child_process'

module.exports = class GitRequire
  constructor: (@projectDir) ->
    @config = null
    @reposDir = null
    @repos = {}
    @repoList = []

  init: (cb) ->
    @readConfig (err) =>
      dir = process.env.GIT_REQUIRE_DIR or @config.dir or 'git-require'
      @reposDir = path.resolve @projectDir, dir
      @initRepos()
      cb()

  action: (action, cb) ->
    fn = @['action_' + action]
    return cb 'no-such-action' unless fn
    fn.bind(@) cb

  readConfig: (cb) ->
    file = path.join @projectDir, 'git-require.json'
    fs.readFile file, {encoding: 'utf8'}, (err, data) =>
      return cb err if err
      try
        @config = JSON.parse data
      catch
        return cb 'failed-to-parse-json'
      cb()

  initRepos: ->
    for name, data of @config.repos
      repo =
        name: name
        url: data
        dir: path.join @reposDir, name
      @repos[name] = repo
      @repoList.push repo
    @repoList.sort (a, b) ->
      if a.name > b.name then 1
      else if a.name < b.name then -1 else 0
    return

  action_install: (cb) ->
    async.mapSeries @repoList, @installRepo.bind(@), cb

  action_list: (cb) ->
    for repo in @repoList
      console.log repo
    return

  installRepo: (repo, cb) ->
    fs.exists repo.dir, (exists) =>
      if exists
        @updateRepo repo, cb
      else
        @cloneRepo repo, cb

  updateRepo: (repo, cb) ->
    console.log 'Updating', repo.name, 'into', repo.dir
    exec """
      cd '#{repo.dir}'
      git pull
    """, cb

  cloneRepo: (repo, cb) ->
    console.log 'Cloning', repo.url, 'in', repo.dir
    run 'git', ['clone', repo.url, repo.dir], cb

run = (name, args, cb) ->
  p = spawn name, args
  p.stdout.on 'data', (data) -> process.stdout.write data
  p.stderr.on 'data', (data) -> process.stderr.write data
  p.on 'close', (code) ->
    return cb 'code-' + code unless code is 0
    cb()
