class @Wiblit.HighNumber extends @Wiblit.Game
  constructor: (@el) ->
    # Contains the game metadata

    super @el # Call parent class' constructor, which contains a full list of default values
    
    @title = "High Time" # The game title that is displayed
    @duration = 3 # The duration of each round of the game
    @countdown = 10 # The time

    @optimalRounds = 5 # The recommended number of rounds to play in one game (typically 3)
    @optimalPractice = 1 # The recommended number of practice rounds to play (typically 1)

    @singleGameContestEnabled = true # This game is enabled to play as a single-game contest
    @randomStreamEnabled = true # This game is enabled to play in "tournament" style
    @challengeEnabled = false # This game is not enabled to play as an on-demand challenge

    @winnerType = "max" # Does max or min points win the game?
    @tiebreakerDescription = "fastest total time (in seconds) to select their numbers"
    @tiebreakerMaxOrMin = "min" # Does max or min tiebreaker points win?
    @tiebreakerRoundOrTotal = "total" # Is the tiebreaker score selected from the best round
    # or accumulated over all of the rounds?
    @roundScoreDecimal = false # Does the score need to be rounded to two decimal points?
    @roundTBDecimal = true # Does the tiebreaker score need to be rounded to two decimal points?

    @description = "Press the highest number in less than " + @duration +
    " seconds!  You score the amount on the button you press.  Hurry, or else you'll score zero!"
    @shortDescription = "Find the highest number in #{@duration} seconds"
  

  @configure: ->
    # Called by the server
    # Randomizes the game data, so that it is different each round

    # In this case, it randomizes the numbers from 10-100 that
    # will be shown on the 16 buttons.  A different range of numbers
    # is also given each round so that you don't know what to expect
    # as the highest number.

    tenSelection = 100
    range = Math.floor Math.random() * (tenSelection*.8) + (tenSelection*.1)
    startingNumber = Math.floor(Math.random()* ((tenSelection*.9) - range)) + (tenSelection*.1)
    configuration =
      one: Math.floor (range * Math.random() + startingNumber)
      two: Math.floor (range * Math.random() + startingNumber)
      three: Math.floor (range * Math.random() + startingNumber)
      four: Math.floor (range * Math.random() + startingNumber)
      five: Math.floor (range * Math.random() + startingNumber)
      six: Math.floor (range * Math.random() + startingNumber)
      seven: Math.floor (range * Math.random() + startingNumber)
      eight: Math.floor (range * Math.random() + startingNumber)
      nine: Math.floor (range * Math.random() + startingNumber)
      ten: Math.floor (range * Math.random() + startingNumber)
      eleven: Math.floor (range * Math.random() + startingNumber)
      twelve: Math.floor (range * Math.random() + startingNumber)
      thirteen: Math.floor (range * Math.random() + startingNumber)
      fourteen: Math.floor (range * Math.random() + startingNumber)
      fifteen: Math.floor (range * Math.random() + startingNumber)
      sixteen: Math.floor (range * Math.random() + startingNumber)

    return configuration

  start: ->
    # Play the game
    
    super() # Calls the parent's start method to set default values & config

    Session.set "gameInstructions", "Choose the highest!" # Sets the
    # instructions shown at the top of the page

    # Uses the configuration object from the server to populate the game data
    buttons =
      one: @configuration.one
      two: @configuration.two
      three: @configuration.three
      four: @configuration.four
      five: @configuration.five
      six: @configuration.six
      seven: @configuration.seven
      eight: @configuration.eight
      nine: @configuration.nine
      ten: @configuration.ten
      eleven: @configuration.eleven
      twelve: @configuration.twelve
      thirteen: @configuration.thirteen
      fourteen: @configuration.fourteen
      fifteen: @configuration.fifteen
      sixteen: @configuration.sixteen
    
    # Configure and append the game buttons to the page
    div = $('<div class="highnumber"></div>')
    @el.append div

    headerDiv = $(".highnumber")
    buttonDiv = $('<div class="buttons"></div>')
    headerDiv.append buttonDiv
    
    counter = 0
    _.each buttons, (value, key) =>
      b = $("<button>")
      b.addClass "btn btn-default btn-lg game-select hn-select"
      b.attr "data-value", value
      b.html value
      buttonDiv.append b
      counter++
      if counter % 4 == 0
        buttonDiv.append $("<br/>")
    
    # Once the player clicks, set the chosen value, highlight the
    # button, and finish
    $(".game-select", @el).click (e) =>
      return if @value
      val = $(e.target).attr "data-value"
      @points = val
      @selection = $(e.target).html()
      @value = @points
      @finishTime = Date.now()

      $(e.target).css({"background-color":"green", "color":"white"})

      Meteor.setTimeout () =>
        @finish()
      , 1000

    @startTime = Date.now()

    return

  finish: ->
    # Calculate the final score & tiebreaker values
    # The @value property is the one that is shown on the results page;
    # sometimes it is just the player's points, but sometimes it is more descriptive

    unless @value?
      @value = "too slow" 
    if @finishTime?
      @tiebreaker =  (@finishTime - @startTime)/1000
      @tiebreaker = Math.round(@tiebreaker * 100) / 100
    else
      @tiebreaker = @duration

    # Call parent class' finish method to record the score on the server
    super()

    return