request = require "request"

class WalletsClient

  host: null

  commands:
    "create_account": "post"

  constructor: (options = {})->
    @host = options.host if options.host

  send: (command, data, callback = ()->)->
    url = "http://#{@host}/#{command}"
    for param in data
      url += "/#{param}"
    if @commands[command]
      try
        request[@commands[command]](url, {json: true}, callback)
      catch e
        console.error e
        callback "Bad response '#{e}'"
    else
      callback "Invalid command '#{command}'"

exports = module.exports = WalletsClient