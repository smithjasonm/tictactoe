# Overview

Tic-Tac-Toe is a web application built with [Ruby on Rails](http://rubyonrails.org/) 5. It is intended for purposes of demonstration and can be [viewed on Heroku.](https://tictactoe-rails-demo.herokuapp.com/) This document describes the salient technologies on which the application relies, its use, and its basic architecture.

# Technologies

## Turbolinks

For ease and productivity of development and maintenance, the application favors the use of [Turbolinks](https://github.com/turbolinks/turbolinks) rather than the use of a client-side JavaScript framework. Turbolinks offers fast page reloads as a viable alternative to client-side view rendering.

## Action Cable

The application makes extensive use of [Action Cable](https://github.com/rails/rails/tree/master/actioncable), which facilitates the use of [WebSockets](https://en.wikipedia.org/wiki/WebSocket) in Rails 5 for bidirectional communication between client and server. Such communication permits the real-time gameplay that is essential to the application.

## CoffeeScript

Action Cable requires client-side code to handle the disposition of messages to and from the server. In this application, [CoffeeScript](http://coffeescript.org/), favored by Rails, is used for this purpose.

## Bootstrap

The application uses [Bootstrap](http://getbootstrap.com/), the front-end Web framework, as the foundation for its views.

# Use

## Registration and Login
On visiting the application for the first time, a user is presented with a welcome page that includes an invitation to start playing. Following the corresponding link will take the user to a registration page, where the user will be asked to provide a username, email address, and password. After these have been submitted and validated, an account will be created for the user, who will then be logged in and redirected to the games page.

A login form is provided for returning users.

## Games

The games page contains three lists of games:

  - Waiting games
  - Ongoing games
  - Recent games

Waiting games are games that are awaiting a second player. On the games page, they include information about who created the game and when it was created. If a waiting game was created by the user, it is referred to as the user's own waiting game and appears at the top of the user's waiting-games list. A user may have only one such game at a time.

Ongoing games are games that are currently in progress—that is, they are neither waiting nor completed. On the games page, they include a thumbnail of the game as well as information about who the user's opponent is and when the last activity occurred.

Recent games are the last few completed games in which the user participated. On the games page, in addition to linking to the game, they tell who the user's opponent was, the result of the game, and when the game was completed.

From the games page, the user may start a game, join a game, or visit a game that is ongoing, recent, or the user's own waiting game. A game and its associated information may be viewed only by the game's participants.

### Starting a Game

When the user chooses to start a game, the game will be created and the user will be redirected to the game page. This game will begin as a waiting game, as it will not yet have a second player, and so it will appear in the waiting-games lists of all users. The user may await a second player on the game page, or leave and return to it later. The user also has the option of canceling the game before a second player joins. Until then, the game page will present an empty, non-interactive game board.

### Joining a Game

All waiting games will appear in the waiting-games list. Any of these (except the user's own waiting game, if it exists) may be joined by clicking the corresponding "join" button. When the user joins a game, the game will become an ongoing game and the user will be redirected to that game's page. In addition to the game board, this page will now contain the user's record against the current opponent.

### Playing a Game

Player 1 of a game, who plays "X," is the user who created the game. Player 2, who plays "O," is the player who joined the game. Once a game has two players, the first player may make the first play. To make the play, the user clicks on an empty space on the game grid. An "X" will appear, and it will now be the second player's turn. The game progresses in this manner until a player wins or resigns or the game is drawn. The current status of the game appears below the game along with a button, if the game is ongoing, to resign. When the game is completed, it will appear in each user's list of recent games.

### Playing Again
At the conclusion of a game, each player will have the option of inviting the other player to play again. When a user clicks the appropriate button to play again, the user's opponent is given the choice either to accept the invitation or to decline it. If the invited user accepts the invitation, a new game will be created to which both users will be redirected. If the user declines the invitation, the inviting player will be informed of the decision. If the invited user leaves the game page before making a decision, or fails to respond within a given time, the inviting user will notified that the other user failed to respond or was otherwise unavailable to play again.

## Users

### Privacy

A user provides a username, email address, and password when creating an account. Of these, only the user's username will be made public, along with any Gravatar associated with the user's email address. Although email addresses are not made public, users may use a user-lookup tool to determine whether a user exists with a given email address.

### Profiles

Each user has a profile, which contains the user's username, Gravatar, full game record, and (unless the profile belongs to the visiting user) the visiting user's game record against that user. Users may navigate to these profiles either by visiting the users page, which contains a user-lookup tool, or by following a link to the profile provided on a game page. The user-lookup tool permits lookups by username and by email address.

### Settings

Users may change their usernames, email addresses, and passwords by visiting the settings page.

# Architecture

The application includes the following models, controllers, and Action Cable channels:

- Models
  - User
  - Game
  - Play
  - User Session
- Controllers
  - Static Pages
  - Users
  - Games
  - Sessions
- Action Cable channels
  - Games
  - Waiting Games

Each of these is described below.

## Models

### User

The user model represents a user of the application. Each user has a "handle" (i.e., username), email address, password, and any number of created and joined games. The model also provides public methods to perform the following tasks:

 - Create a game
 - Join a game
 - Resign from a game
 - Retrieve the user's game record (complete, or against another user)
 - Retrieve all the games participated in by the user
 - Retrieve the user's ongoing games
 - Retrieve the user's completed games
 - Retrieve the user's own waiting game (i.e., the game, if it exists, created by the user that awaits a second player)

#### Validations

Usernames and email addresses are case-insensitive and must be unique. Usernames must begin with a letter or number, have at least three and no more than 15 characters, and contain only letters, numbers, and underscores. Email addresses may not contain more than 255 characters.

### Game

The game model represents a single game. Each game has a status, 0–9 plays, and 0–2 players. The model also provides public methods to perform the following tasks:

 - Get the number of the next play (each play being numbered from 1–9)
 - Determine whether given x and y values are valid game coordinates
 - Determine whether a given position (i.e, game cell) is available
 - Get the state of a given position—empty, occupied by X, or occupied by O
 - Make a play
 - Register a player's resignation
 - Get the player whose turn it is
 - Get the winning player
 - Determine whether the game is pending (i.e., not completed)
 - Determine whether the game is ongoing
 - Determine whether the game is waiting
 - Determine whether the game is completed
 - Get the coordinate set of the winning three plays—that is, the three plays made by the winning player that fill a single row, column, or diagonal
 - Get a list of all waiting games

#### Constants

Statuses:

 - PENDING
 - P1_WON
 - P2_WON
 - DRAW
 - P1_FORFEIT
 - P2_FORFEIT

#### Validations

A game's status must be an integer ranging from 0-5.

### Play

The play model represents a game play or "move." A play results each time a user adds an X or O to a game board. Each play belongs to a game.

Plays have x and y coordinates, each ranging from 0–2, and a number, 1–9, indicating the play's position in the sequence of plays associated with the game to which it belongs.

The model also provides a public method to get the number (1 or 2) of the player who made the play.

#### Validations

A play's coordinates, x and y, must be integers between 0 and 2, inclusive. Its number must be an integer between 1 and 9, inclusive.

### User Session

The user-session model represents a user session. It stores the current session and cookies and provides public methods to perform the following tasks:

 - Log a user in
 - Log a user out
 - Determine whether a user is logged in
 - Get the user currently logged in

## Controllers

### Static Pages

The static-pages controller serves the pages of the application that do not change for each user and are not handled by another controller. Currently, only one such page exists, namely, the home page. Logged-in users who navigate to the home page are redirected to the games page.

### Users

The users controller includes actions to perform the following tasks:

 - Display a user-lookup tool
 - Display a user profile
 - Display a form to register a new user
 - Display a form to edit a user's settings
 - Register a new user
 - Update a user's settings
 - Remove a user
 - Find a user by username or email address

### Games

The games controller includes actions to perform the following tasks:

 - Display the games page, which includes waiting, ongoing, and completed games
 - Display a single game's page
 - Create a game
 - Add a second player to a game or register a player's resignation
 - Cancel a game

### Sessions

The sessions controller handles logging in and logging out. It includes actions to perform the following tasks:

 - Display a login form
 - Log a user in
 - Log a user out

## Action Cable Channels

Action Cable is an essential element of the application's architecture. It provides the mechanism by which the application client can be updated in real time with messages broadcast from the server. The application uses this capacity to facilitate updates both to ongoing games and to lists of waiting games.

### Games

The application provides a games channel to which a client may subscribe to receive updates to its ongoing games. Only a game's participants may subscribe to updates for that game. This channel broadcasts a message whenever a player makes a play, a second player joins, or a player resigns. On receipt of this message, the application client updates the relevant views.

In addition to receiving messages through the games channel, the application client transmits a message to the server each time a player makes a play, sends an invitation to play again, or responds to such an invitation.

### Waiting Games

The waiting-games channel allows clients to subscribe for updates to their lists of waiting games. A message is broadcast through this channel each time a game is started from the games page, joined, or canceled. On receipt of a message from this channel while a waiting-games list is displayed, the application client either appends a game to its waiting-games list or removes one, according to the type of message received.

Copyright © 2016 Jason Smith