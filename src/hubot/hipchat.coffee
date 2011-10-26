Robot   = require 'robot'
Xmpp    = require 'node-xmpp'
Request = require 'request' # http://github.com/mikeal/request

# https://gist.github.com/940969

class HipChatBot extends Robot

  # Implement Timer
  # Implement Group Functionally
  # Implement Lunch Feature
  
  # (TODO) change this to xmpp callback
  send: (user, strings...) ->
    strings.forEach (str) =>
      console.log "#{user.name}: #{str}"
      @bot.say user.room, str

  reply: (user, strings...) ->
    strings.forEach (str) =>
      @send user, "#{user.name}: #{str}"

  run: ->
    self = @
    @options =
      auth_token: process.env.HUBOT_HIPCHAT_AUTH_TOKEN
      username:   process.env.HUBOT_HIPCHAT_USERNAME
      password:   process.env.HUBOT_HIPCHAT_PASSWORD
      nickname:   process.env.HUBOT_HIPCHAT_NICKNAME
      server:     'chat.hipchat.com'

      # GET THIS FROM API INSTEAD
      #rooms:    process.env.HUBOT_HIPCHAT_ROOMS.split(',')

    console.log @options

    # /bot is attached to prevent the chat history from being displayed
    bot = new Xmpp.Client
      jid: "#{@options.username}@#{@options.server}/bot"
      password: @options.password


    bot.on 'online', ->
      console.log "We're online!"

      # set bot as available
      bot.send new xmpp.Element('presence', { type: 'available' }).
        c('show').t('chat').
        c('status').t('I am but a bot')

      # using the hipchat api, grab the rooms feed and login to ach room
      uri = "https://api.hipchat.com/v1/rooms/list?format=json&auth_token=#{@options.auth_token}"
      request = {'uri': uri}, (error, response, body) ->
        data = JSON.parse(body)
        for room in data.rooms
          unless room.is_archived
            room_jid = room.xmpp_jid
            bot.send new xmpp.Element('presence', { to: "#{room_jid}/#{@options.nickname}" }).
              c('x', { xmlns: 'http://jabber.org/protocol/muc' })

      # send keepalive data or server will disconnect us after 150s of inactivity
      setInterval -> bot.send ' ', 30000

    
      bot.on 'stanza', (stanza) ->
        # always log error stanzas
        if stanza.attrs.type is 'error'
          console.log "[error] #{stanza}"
          return

        # ignore everything that isn't a room message
        return if !stanza.is('message') or !stanza.attrs.type == 'groupchat'

        # ignore messages we sent
        return if stanza.attrs.from.is("#{room_jid}/#{room_nick}")

        body = stanza.getChild('body')
        # message without body is probably a topic change
        return unless body

        message = body.getText()
        console.log message

        # Do Stuff
        bot.send new xmpp.Element('message', { to: "#{room_jid}/#{room_nick}", type: 'groupchat' }).
          c('body').t('hi my name is hubot')

      @bot = bot
   
exports.HipChatBot = HipChatBot

