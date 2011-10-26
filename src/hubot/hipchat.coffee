Robot = require 'robot'
Xmpp  = require 'node-xmpp'

# https://gist.github.com/940969

class HipChatBot extends Robot

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
    options =
      username: process.env.HUBOT_HIPCHAT_USERNAME
      password: process.env.HUBOT_HIPCHAT_PASSWORD
      nickname: process.env.HUBOT_HIPCHAT_NICKNAME
      rooms:    process.env.HUBOT_HIPCHAT_ROOMS.split(',')
      server:   'chat.hipchat.com'

    console.log options

    bot = new Xmpp.Client
      jid: "#{options.username}@#{options.server}"
      password: options.password

    # unused...
    [next_id, user_id] = [1, {}]

    bot.on 'online', ->
      console.log "We're online!"

      # set bot as available
      bot.send new xmpp.Element('presence', { type: 'available' }).
        c('show').t('chat')

      # join room (and request no chat history)
      bot.send new xmpp.Element('presence', { to: "#{room_jid}/#{room_nick}" }).
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

