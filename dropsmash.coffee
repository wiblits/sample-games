class @Wiblit.Dropsmash extends @Wiblit.PhaserBase
  constructor: (@el) ->
    # Contains the game metadata

    super @el # Call parent class' constructor, which contains a full list of default values

    @title = "Dropsmash" # The game title that is displayed
    @duration = 20 # The duration of each round of the game
    @countdown = 10 # The time
    
    @winnerType = "max" # Does max or min points win the game?
    @tiebreakerDescription = "fewest total seconds to reach their score"
    @tiebreakerMaxOrMin = "min" # Does max or min tiebreaker points win?
    @tiebreakerRoundOrTotal = "total" # Is the tiebreaker score selected from the best round
    # or accumulated over all of the rounds?

    @roundScoreDecimal = true # Does the score need to be rounded to two decimal points?
    @roundTBDecimal = true # Does the tiebreaker score need to be rounded to two decimal points?

    @optimalRounds = 3 # The recommended number of rounds to play in one game (typically 3)
    @optimalPractice = 1 # The recommended number of practice rounds to play (typically 1)

    @singleGameContestEnabled = true # This game is enabled to play as a single-game contest
    @randomStreamEnabled = true # This game is enabled to play in "tournament" style
    @challengeEnabled = true # This game is enabled to play as an on-demand challenge
    @desktopFriendly = true # This game is enabled to play by users on desktop computers

    @finished = false # Initialize game as not finished
    @score = 0 # Set users' initial score
    @finalPoint = null # The timestamp of the final point scored, initially null

    @description = "Drop the ball to smash the moving platform.
                    \n\nTap your screen to release the ball.  Each time the 
                    ball hits the rotating platform below, you get 1 point.
                    Most points wins!"
    @shortDescription = "Time the drop of the ball to hit the platform"
    return

  finish:->
    # Calculate the final score & tiebreaker values
    # The @value property is the one that is shown on the results page;
    # sometimes it is just the player's points, but sometimes it is more descriptive

    if @finalPoint?
      @tiebreaker =  (@finalPoint - @startTime)/1000
      @tiebreaker = Math.round(@tiebreaker * 100) / 100
    else
      @tiebreaker = @duration

    @points = @value = @score
    
    # Call parent class' finish method to record the score on the server
    super()
    
    return

  @configure: ->
    # Called by the server
    # Randomizes the game data, so that it is different each round

    # In this case, it randomizes the length of time the paddle takes
    # to tween back and forth.
    configuration = 
      paddleDuration : (Math.random() * 1300) + 700

    return configuration

  start:->
    # Play the game
    super("main") # Calls the parent's start method to set default values & config for main state
    @startTime = Date.now()
    Session.set "gameInstructions", "Tap to release the ball"  # Sets the
    # instructions shown at the top of the page
    return

  preload:->
    # Need to call preload in order to setup the phase game if none have been setup
    super()
    game = window.phaserGame 

    # If the old phaser game we are using does not equal the one that is currenty loaded, 
    # unpause and time to make a new one
    if game.name != @title
      game.paused = false
      game.name = @title
    else 
      return

    windowWidth = 300
    windowHeight = 300
    game = window.phaserGame 
    preloadState = 
      preload:->
        game.load.image('ball', 'ballDrop/ball.png')
        game.load.image('bucket','ballDrop/bucket.png')
        game.load.image('particle','particles/pink.png')
        game.stage.disableVisibilityChange = true
        game.stage.backgroundColor = '#ffffff'
        return
      create :->
        Phaser.Canvas.removeFromDOM game.canvas
        return

    mainState = 
      preload: ->
        game.stage.disableVisibilityChange = true
        game.stage.backgroundColor = '#ffffff'
        return
      create:->
        # Need to resize the canvas because we hid it to being with
        game.scale.setGameSize(windowWidth, windowHeight)
        game.physics.startSystem(Phaser.Physics.ARCADE)

           
       
        # Set the a random position for the bucekt
        @bucket = game.add.sprite(50, 290 ,'bucket')
        @bucket.tint = 0xff00f8 #0xff0000
        game.physics.enable(@bucket, Phaser.Physics.ARCADE);
        offSet = @bucket.width/2
        # Reset the position to be half the width of the bucket
        @bucket.reset offSet, @bucket.y
        @bucket.anchor.setTo(0.5,0.5)

        # The tween will move the bucket back and forth
        tween = game.add.tween(@bucket);
        tween.to( { x: windowWidth - (@bucket.width/2) }, game.wibObject.configuration.paddleDuration)
        tween.to( { x: @bucket.x}, game.wibObject.configuration.paddleDuration)  
        tween.loop().start() #loop the tween

        # Create a ball in the middle of the screen
        @ball = game.add.sprite(windowWidth/2,45,'ball')
        @ball.anchor.setTo(0.5,0.5)
        @ball.tint = 0xff00f8
        game.physics.enable(@ball, Phaser.Physics.ARCADE);
    
        # Variable to know when we clicked the ball to drop
        @ballDrop = false
        # Add an on down event to know when we click
        game.input.onDown.add(@click, this);


        # Particle emitter
        @emitter = game.add.emitter(50, 50);
        @emitter.makeParticles('particle', 1, 20, false, false);
        @emitter.minParticleScale = 0.25;
        @emitter.maxParticleScale = 0.4;

        # When the game pauses call this function
        game.onPause.add(@onGamePause, this);

        return

      # Function called when the game pauses, clears the screen
      deleteCharacter:(item)->
        if typeof item.kill == typeof(Function) and item.alive
          item.kill()
        return

      # Called when the game is paused
      onGamePause:->
        game.world.forEach(@deleteCharacter,this)
        return

      # Called when we click the game screen
      click:->
        @ballDrop = true
        @ball.body.gravity.y = 500 #set the gravity to 500
        game.wibObject.noActionTaken = false
        return

      # When the ball collides with the platofrm increase the score, do partciles and reset the ball
      ballCollision:(ball,bucket)->
        game.wibObject.finalPoint = Date.now()
        game.wibObject.score++
        @emitter.x = ball.x
        @emitter.y = ball.y
        @emitter.start(true,1000,1,20,true)
        @resetBall()

        if game.wibObject.score is 1
          Session.set "gameInstructions", "#{game.wibObject.score} point"
        else if game.wibObject.score > 1
          Session.set "gameInstructions", "#{game.wibObject.score} points"

        return

      # Reset the ball function
      resetBall:->
        @ball.kill()
        @ball.reset windowWidth/2,45
        @ball.body.gravity.y = 0
        @ballDrop = false
        return
      # If the ball fell lower than the screen, reset it
      update:->
        if @ball.y > (@bucket.y + @ball.height) and @ball.alive
          @resetBall()
        # If we have dropped the ball check for overlap of the sprites
        if @ballDrop
          game.physics.arcade.overlap(@ball, @bucket, @ballCollision, null, this)
        return

    # Push in the states and start the preload one to load the assets
    game.state.add("preload",preloadState)
    game.state.add("main", mainState)
    game.state.start("preload")
    return