module.exports = Worker =
  listening:false # TODO: Spec out the listening state
  processing:false # TODO: Spec out the processing state
  delay:10000 # Delay between jobs being processed
  eventTally:0 # Keep a running tally of events to compare against tippingPoin
  tippingPoint:40 # Point at which it gets cray
  # The list of possible events that lead up to holicray
  events:[ #TODO: Finalize events and sync up with job processes and spec
    'it snow'
    'the lights on the tree blink'
    'the stars light up'
    'the discoball spin'
    'the wacky man dance'
    'the foo bar baz'
  ]



  # #### Setup Worker with jobs, a logger, and a restored state starting tally
  init: (@jobs, @logger, tally) ->
    @eventTally = tally



  #
  # #### Conditionally start Worker
  #
  #   - Start processing jobs if arduino is connected
  #   - Start listening on websocket events unless already listening
  #
  start: (socket) ->
    unless @processing is true then @processJobs socket
    unless @listening is true then @listen socket



  # Listen for websocket events
  listen: (socket) ->
    socket.on 'right now', -> socket.emit 'refresh stats'
    @listening = true



  # Assign an incoming tweet to an arduino event
  assign: (tweet) ->
    @tally()
    if @eventTally is @tippingPoint then event = 'holicray'
    else event = @random()
    @assembleJob event, tweet



  # Pick a random event
  random: ->
    randomize = -> return (Math.round(Math.random())-0.5)
    randomEvent = @events.sort @randomize
    event = randomEvent.pop()
    return event



  # Increment eventTally to reach tippingPoint
  tally: ->
    @eventTally++
    return @eventTally



  # Assemble jobData from the incoming tweet data
  assembleJob: (type, data) ->
    jobData =
      title:data.text
      handle:data.user.screen_name
      avatar:data.user.profile_image_url
      event:type
    @createJob type, jobData



  # Create a new job and log job promotion and job completion
  createJob: (type, jobData) ->
    job = @jobs.create(type, jobData).attempts(3).delay(@delay).save()
    job.on 'promotion', -> console.log "10 second pause complete"
    job.on 'complete', -> console.log "Job complete"



  # Process jobs and emit assignment to arduino
  processJobs: (socket) ->
    @processing = true

    process = (job, done) =>
      @logger.arduino "##{job.data.event} by @#{job.data.handle}"
      socket.emit 'action assignment', job
      done()

    @jobs.promote()

    @jobs.process 'it snow', (job, done) ->
      process job, done

    @jobs.process 'the lights on the tree blink', (job, done) ->
      process job, done

    @jobs.process 'the stars light up', (job, done) ->
      process job, done

    @jobs.process 'the discoball spin', (job, done) ->
      process job, done

    @jobs.process 'the wacky man dance', (job, done) ->
      process job, done

    @jobs.process 'the foo bar baz', (job, done) ->
      process job, done

    @jobs.process 'holicray', (job, done) ->
      process job, done
