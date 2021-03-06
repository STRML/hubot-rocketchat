Asteroid = require 'asteroid'

# TODO:   need to grab these values from process.env[]

_msgsubtopic = 'stream-messages' # 'messages'
_msgsublimit = 10   # this is not actually used right now
_messageCollection = 'stream-messages'

# driver specific to Rocketchat hubot integration
# plugs into generic rocketchatbotadapter

class RocketChatDriver
  constructor: (url, @logger, cb) ->
    @asteroid = new Asteroid(url)

    @asteroid.on 'connected', ->
      cb()

  getRoomId: (roomid) =>
    @logger.info "Joining Room: #{roomid}"

    r = @asteroid.call 'getRoomIdByNameOrId', roomid

    return r.result

  joinRoom: (userid, uname, roomid, cb) =>
    @logger.info "Joining Room: #{roomid}"

    r = @asteroid.call 'joinRoom', roomid

    return r.updated

  sendMessage: (text, roomid) =>
    @logger.info "Sending Message To Room: #{roomid}"

    @asteroid.call('sendMessage', {msg: text, rid: roomid})

  login: (username, password) =>
    @logger.info "Logging In"
    # promise returned
    return @asteroid.loginWithPassword username, password

  prepMeteorSubscriptions: (data) =>
    # use data to cater for param differences - until we learn more
    #  data.uid
    #  data.roomid
    # return promise
    @logger.info "Preparing Meteor Subscriptions.."
    msgsub = @asteroid.subscribe _msgsubtopic, data.roomid, _msgsublimit
    @logger.info "Subscribing to Room: #{data.roomid}"
    return msgsub.ready

  setupReactiveMessageList: (receiveMessageCallback) =>
    @logger.info "Setting up reactive message list..."
    @messages = @asteroid.getCollection _messageCollection

    rQ = @messages.reactiveQuery {}
    rQ.on "change", (id) =>
      # awkward syntax due to asteroid limitations
      # - it ain't no minimongo cursor
      @logger.info "Change received on ID " + id
      changedMsgQuery = @messages.reactiveQuery {"_id": id}
      if changedMsgQuery.result && changedMsgQuery.result.length > 0
        # console.log('result:', JSON.stringify(changedMsgQuery.result, null, 2))
        changedMsg = changedMsgQuery.result[0]
        # console.log('changed:', JSON.stringify(changedMsg, null, 2));
        if changedMsg.args?
          receiveMessageCallback changedMsg.args[1]

  callMethod: (name, args = []) =>
    @logger.info "Calling: #{name}, #{args.join(', ')}"
    r = @asteroid.apply name, args
    return r.result

module.exports = RocketChatDriver
