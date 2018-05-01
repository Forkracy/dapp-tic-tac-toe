pragma solidity ^0.4.23;
//pragma experimental ABIEncoderV2;

contract TicTacToe {
    uint constant boardSize = 3;
    address contractOwner;

    enum GameState { NOT_EXISTING, EMPTY, WAITING_FOR_O, WAITING_FOR_X, READY, X_HAS_TURN, O_HAS_TURN, WINNER_X, WINNER_O, DRAW }
    enum BetState { NOT_EXISTING, MISSING_X_BETTOR, MISSING_O_BETTOR, WITHDRAWN, FIXED, PAYEDOUT }
    enum SquareState { EMPTY, X, O }


    constructor() public {
        contractOwner = msg.sender;
    }


    // Players
    mapping(address => Player) public players;        // address = key, Player is value

    // Games
    uint counter = 0;
    mapping(uint => Game) public games;
    uint[] openGameIds;

    // bets
    uint betCounter = 0;
    mapping(uint => Bet) public bets;
    uint[] openBetIds;

    struct Player {
        bytes32 name;
        uint[] gameIds;
    }

    struct Game {
        uint gameId;
        bytes32 name;
        address ownerAddr;

        GameState state;

        uint moveCounter;

        address playerOAddr;
        address playerXAddr;

        address winnerAddr;

        SquareState[boardSize][boardSize] board;
    }

    struct Bet {
        uint value;
        uint gameId;
        uint betId;
        BetState state;
        address bettorOnOAddr;
        address bettorOnXAddr;
    }

    event GameCreated(bool wasSuccess, uint gameId, GameState state, string message);
    function createGame(bytes32 gameName, bytes32 playerName) public returns (uint gameId) {
        gameId = counter++;
        Game storage myGame = games[gameId];

        myGame.gameId = gameId;
        myGame.name = gameName;
        myGame.ownerAddr = msg.sender;
        myGame.state = GameState.EMPTY;

        joinGame(gameId, playerName);

        openGameIds.push(gameId);

        emit GameCreated(true, gameId, myGame.state, "Game created");
        return gameId;
    }


    function getGameIds() public view returns (uint[] gameIds) {
        return openGameIds;
    }

    function getGames() public view returns (uint[] gameIds, GameState[] gameStates, bytes32[] gameNames
            , address[] owners, bytes32[] ownerNames, address[] playerXs, address[] playerOs) {

        gameIds = new uint[](openGameIds.length);
        gameStates = new GameState[](openGameIds.length);
        gameNames = new bytes32[](openGameIds.length);
        owners = new address[](openGameIds.length);
        ownerNames = new bytes32[](openGameIds.length);
        playerXs = new address[](openGameIds.length);
        playerOs = new address[](openGameIds.length);

        for(uint i=0; i<openGameIds.length; i++) {
            Game memory game = games[openGameIds[i]];
            gameIds[i] = game.gameId;
            gameStates[i] = game.state;
            gameNames[i] = game.name;
            owners[i] = game.ownerAddr;
            ownerNames[i] = players[game.ownerAddr].name;
            playerXs[i] = game.playerXAddr;
            playerOs[i] = game.playerOAddr;
        }
        return (gameIds, gameStates, gameNames, owners, ownerNames, playerXs, playerOs);
    }

    event Joined(bool wasSuccess, uint gameId, GameState state, bytes32 playerName, string symbol);
    function joinGame(uint gameId, bytes32 playerName) public {
        Game storage game = games[gameId];

        require(game.state != GameState.NOT_EXISTING, "The game does not exist.");
        require(game.state < GameState.READY, "The game is full." );

        players[msg.sender].name = playerName;

        if(game.state == GameState.EMPTY) {
            game.playerOAddr = msg.sender;
            game.state = GameState.WAITING_FOR_X;

            emit Joined(true, game.gameId,game.state, playerName, "O");
        }
        else if (game.state == GameState.WAITING_FOR_X) {
            //require(game.playerOAddr != msg.sender, "Player is already part of this game.");

            game.playerXAddr = msg.sender;
            game.state = GameState.READY;

            emit Joined(true, game.gameId,game.state, playerName, "X");
        }
        else if (game.state == GameState.WAITING_FOR_O) {
            //require(game.playerXAddr != msg.sender, "Player is already part of this game.");

            game.playerOAddr = msg.sender;
            game.state = GameState.READY;

            emit Joined(true, game.gameId,game.state, playerName, "O");
        }
    }


    event Left(bool wasSuccess, uint gameId, GameState state, bytes32 playerName, string symbol);
    function leaveGame(uint gameId) public {
        Game storage game = games[gameId];
        require(game.state != GameState.NOT_EXISTING, "The game does not exist.");
        require(game.state <= GameState.READY, "The game is already started." );
        require(game.playerOAddr == msg.sender || game.playerXAddr == msg.sender, "Player is not part of this game.");

        if (game.state == GameState.WAITING_FOR_X && game.playerOAddr == msg.sender ) {
            game.playerOAddr = address(0);
            game.state = GameState.EMPTY;
            emit Left(true, game.gameId, game.state, players[msg.sender].name, "O");
        }
        else if (game.state == GameState.WAITING_FOR_O && game.playerXAddr == msg.sender ) {
            game.playerXAddr = address(0);
            game.state = GameState.EMPTY;
            emit Left(true, game.gameId, game.state, players[msg.sender].name, "X");
        }
        else if (game.state == GameState.READY && game.playerXAddr == msg.sender ) {
            game.playerXAddr = address(0);
            game.state = GameState.WAITING_FOR_X;
            emit Left(true, game.gameId, game.state, players[msg.sender].name, "X");
        }
        else if (game.state == GameState.READY && game.playerOAddr == msg.sender ) {
            game.playerOAddr = address(0);
            game.state = GameState.WAITING_FOR_O;
            emit Left(true, game.gameId, game.state, players[msg.sender].name, "O");
        }
    }

    event GameStarted(bool wasSuccess, uint gameId, GameState state, string message);
    function startGame(uint gameId) public {
        Game storage game = games[gameId];

        require(game.state != GameState.NOT_EXISTING, "The game does not exist.");
        require(game.state == GameState.READY, "Not enough players to start the game.");
        require(game.ownerAddr == msg.sender, "Only the game owner can start the game.");

        initialize(gameId);
        game.state = GameState.X_HAS_TURN;
        emit GameStarted(true, gameId, game.state, "game has been started.");
    }

    function initialize(uint gameId) private {
        SquareState[boardSize][boardSize] storage board = games[gameId].board;
        for (uint y = 0; y < boardSize; y++) {
            for (uint x = 0; x < boardSize; x++) {
                board[y][x] = SquareState.EMPTY;
            }
        }
    }

    function getBoard(uint gameId) public view returns (SquareState[boardSize*boardSize]) { // apparently no string array can be returned yet in solidity
        SquareState[boardSize][boardSize] memory board = games[gameId].board;
        SquareState[boardSize*boardSize] memory boardRep;
        uint i=0;
        for(uint y = 0; y < boardSize; y++) {
            for(uint x = 0; x < boardSize; x++) {
                boardRep[i++] = board[y][x];
            }
        }
        return boardRep;
    }

    event MoveMade(bool success, uint gameId, GameState state, uint x, uint y, string symbol);
    function playMove(uint gameId, uint x, uint y) public {
        Game storage game = games[gameId];

        require(game.state >= GameState.X_HAS_TURN, "The game is not started yet.");
        require(game.state < GameState.WINNER_X, "The game is already finished.");

        if (game.state == GameState.X_HAS_TURN) {
            require(game.playerXAddr == msg.sender, "Sender not equal player X");
            require(game.board[y][x] == SquareState.EMPTY, "Move not possible because the square is not empty.");

            game.board[y][x] = SquareState.X;
            game.moveCounter += 1;
            game.state = GameState.O_HAS_TURN;
            checkForWinner(x, y, gameId, game.playerXAddr);

            emit MoveMade(true, gameId, game.state, x, y, "X");
        }
        else {
            require(game.playerOAddr == msg.sender, "Sender not equal player O");
            require(game.board[y][x] == SquareState.EMPTY, "Move not possible because the square is not empty.");

            game.board[y][x] = SquareState.O;
            game.moveCounter += 1;
            game.state = GameState.X_HAS_TURN;
            checkForWinner(x, y, gameId, game.playerOAddr);

            emit MoveMade(true, gameId, game.state, x, y, "O");
        }
    }

    function checkForWinner(uint x, uint y, uint gameId, address currentPlayer) private {
        Game storage game = games[gameId];

        //is winning already possible?
        if(game.moveCounter < 2*boardSize -1) {
            return;
        }

        SquareState[boardSize][boardSize] memory board = game.board;
        SquareState symbol = game.board[y][x];

        //check column
        for (uint i = 0; i < boardSize; i++) {
            if (board[i][x] != symbol)  {
                break;
            }
            else if(i == (boardSize -1)) {
                game.winnerAddr = currentPlayer;
                game.state = getGameState(symbol);
                payoutBet(game.gameId);
                return;
            }
        }

        //check row
        for (i = 0; i < boardSize; i++) {
            if(board[y][i] != symbol) {
                break;
            }
            else if(i == (boardSize -1)) {
                game.winnerAddr = currentPlayer;
                game.state = getGameState(symbol);
                payoutBet(game.gameId);
                return;
            }
        }

        //check diagonal
        if(x == y) {
            for (i = 0; i < boardSize; i++) {
                if(board[i][i] != symbol) {
                    break;
                }
                else if(i == (boardSize -1)) {
                    game.winnerAddr = currentPlayer;
                    game.state = getGameState(symbol);
                    payoutBet(game.gameId);
                    return;
                }
            }
        }

        // check anti diagonal
        if(x + y == (boardSize -1)) {
            for (i = 0; i < boardSize; i++) {
                if(board[x][boardSize-1-i] != symbol) {            //!equalStrings(board[x][(boardSize-1) - 1], symbol)) {
                    break;
                }
                else if(i == (boardSize -1)) {
                    game.winnerAddr = currentPlayer;
                    game.state = getGameState(symbol);
                    payoutBet(game.gameId);
                    return;
                }
            }
        }

        //check for draw
        if (game.moveCounter == boardSize*boardSize) {
            game.state = GameState.DRAW;
        }
    }

    function getGameState(SquareState symbol) private pure returns (GameState state) {
        if (symbol == SquareState.X)
            return GameState.WINNER_X;
        else
            return GameState.WINNER_O;
    }

    event BetCreated(bool wasSuccess, uint betId, BetState state, string message);
    function createBet(uint gameId, bool bettingOnX) public payable returns (uint betId){

        betId = betCounter++;
        Bet storage myBet = bets[betId];

        myBet.betId = betId;
        myBet.gameId = gameId;
        myBet.value = msg.value;

        // x-betting
        if(bettingOnX) {
            myBet.bettorOnXAddr = msg.sender;
            myBet.state = BetState.MISSING_O_BETTOR;
        } else {
            myBet.bettorOnOAddr = msg.sender;
            myBet.state = BetState.MISSING_X_BETTOR;
        }

        openBetIds.push(betId);

        emit BetCreated(true, betId, myBet.state, "Bet created");
        return betId;
    }

    function getBetIds() public view returns (uint[] betIds) {
        return openBetIds;
    }

    event JoinedBet(bool wasSuccess, uint betId, BetState state, string symbol);
    function joinBet(uint betId) payable public {
        Bet storage bet = bets[betId];
        if(msg.value != bet.value) {
            emit JoinedBet(false, betId, bet.state, "Not equal amount of value");
        }else if (msg.sender == bet.bettorOnXAddr || msg.sender == bet.bettorOnOAddr){
            emit JoinedBet(false, betId, bet.state, "Same address on both sides");
        } else if (games[bet.gameId].state >= GameState.WINNER_X){
            emit JoinedBet(false, betId, bet.state, "Game is already finished");
        }
        else {
            if(bet.state == BetState.MISSING_X_BETTOR) {
                bet.bettorOnXAddr = msg.sender;
            } else {
                bet.bettorOnOAddr = msg.sender;
            }
            bet.state = BetState.WITHDRAWN;
            emit JoinedBet(true, betId, bet.state, "Joined Bet");
        }
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function payoutBet(uint gameId) internal {
        for (uint i = 0; i < openBetIds.length; i++) {
            Bet storage iBet = bets[openBetIds[i]];
            if(iBet.gameId == gameId) {
                if(games[gameId].state == GameState.WINNER_X) {
                    (iBet.bettorOnXAddr).transfer(2*(iBet.value));
                } else if(games[gameId].state == GameState.WINNER_O){
                    (iBet.bettorOnOAddr).transfer(2*(iBet.value));
                } else {
                    (iBet.bettorOnOAddr).transfer(iBet.value);
                    (iBet.bettorOnXAddr).transfer(iBet.value);
                }
            }
        }
    }
}


