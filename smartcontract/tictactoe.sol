pragma solidity ^0.4.23;
//pragma experimental ABIEncoderV2;

contract TicTacToe {
    uint constant boardSize = 3;
    address contractOwner;
    
    event SuccessEvent(uint ID, bool returnValue);

    enum GameState { EMPTY, WAITING_FOR_O, WAITING_FOR_X, READY, X_HAS_TURN, O_HAS_TURN, WINNER_X, WINNER_O, DRAW }
    enum BetState { MISSING_X_BETTOR, MISSING_O_BETTOR, WITHDRAWN, FIXED, PAYEDOUT }
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
        string name;
        uint[] gameIds;
    }
    
    struct Game {
        uint gameId;
        string name;
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
        BetState state;
        bool isBettorOSet;
        address bettorOnOAddr;
        bool isBettorXSet;
        address bettorOnXAddr;
        bool isBetFilled;
    }


    function createGame(string gameName, string playerName) public returns (uint gameId) {
        gameId = counter++;
        Game storage myGame = games[gameId];
        
        myGame.gameId = gameId;
        myGame.name = gameName;
        myGame.ownerAddr = msg.sender;

        myGame.playerOAddr = msg.sender;
        players[msg.sender].name = playerName;

        myGame.state = GameState.WAITING_FOR_X;
        openGameIds.push(gameId);
        
        emit SuccessEvent(gameId, true);
        return gameId;
    }

    function getOpenGameIds() public view returns (uint[] gameIds) {
        return openGameIds;
    }
    
    /*function getOpenGames() public view returns (uint[] gameIds, string[] gameNames, string[] ownerNames, string[] playerO, string[] playerX) {
        
        gameIds = new uint[](openGameIds.length);
        gameNames = new string[](openGameIds.length);
        ownerNames = new string[](openGameIds.length);
        playerO = new string[](openGameIds.length);
        playerX = new string[](openGameIds.length);
        
        for(uint i=0; i<openGameIds.length; i++) {
            Game memory game = games[openGameIds[i]];
            gameIds[i] = game.gameId;
            gameNames[i] = game.name;
            ownerNames[i] = players[game.ownerAddr].name;
            playerO[i] = players[game.playerOAddr].name;
            playerX[i] = players[game.playerXAddr].name;
        }
        
        return (gameIds, gameNames, ownerNames, playerO, playerX);
    }*/

    event Joined(uint gameId, string symbol, bool returnValue);
    function joinGame(uint gameId, string playerName) public returns (bool){
        Game storage game = games[gameId];
        
        players[msg.sender].name = playerName;
        
        if(game.state == GameState.EMPTY) {
            game.playerOAddr = msg.sender;
            game.state = GameState.WAITING_FOR_X;
            
            emit Joined(game.gameId,"O", true);
            return true;
        }
        else if (game.state == GameState.WAITING_FOR_X) {
                //&& game.playerOAddr != msg.sender) {
            game.playerXAddr = msg.sender;
            game.state = GameState.READY;
            
            emit Joined(game.gameId, "X", true);
            return true;
        }
        else if (game.state == GameState.WAITING_FOR_O) {
                //&& game.playerXAddr != msg.sender) {
            game.playerOAddr = msg.sender;
            game.state = GameState.READY;
            
            emit Joined(game.gameId, "O", true);
            return true;
        }
        emit Joined(game.gameId, "not possible to join", false);
        return false;
    }
    
    event Left(uint gameId, string symbol, bool returnValue);
    function leaveGame(uint gameId) public returns (bool){
        Game storage game = games[gameId];

        if (game.state == GameState.WAITING_FOR_X
            && game.playerOAddr == msg.sender ) {
            game.playerOAddr = address(0);
            game.state = GameState.EMPTY;
            return true;
        }
        else if (game.state == GameState.WAITING_FOR_O
                && game.playerXAddr == msg.sender ) {
            game.playerXAddr = address(0);
            game.state = GameState.EMPTY;
            return true;
        }
        else if (game.state == GameState.READY
                && game.playerXAddr == msg.sender ) {
            game.playerXAddr = address(0);
            game.state = GameState.WAITING_FOR_X;
            return true;
        }
        else if (game.state == GameState.READY
                && game.playerOAddr == msg.sender ) {
            game.playerOAddr = address(0);
            game.state = GameState.WAITING_FOR_O;
            return true;
        }
        emit Left(game.gameId, "not possible to leave", false);
        return false;
    }
    
    

    function startGame(uint gameId) public returns (bool) {
        Game storage game = games[gameId];
        
        if (game.ownerAddr == msg.sender
            && game.state == GameState.READY ) {
            
            initialize(gameId);
            game.state = GameState.X_HAS_TURN;
            return true;
        }
        return false;
    }
    
    function initialize(uint gameId) private {
        SquareState[boardSize][boardSize] storage board = games[gameId].board;
        for (uint y = 0; y < boardSize; y++) {
            for (uint x = 0; x < boardSize; x++) {
                board[y][x] = SquareState.EMPTY;
            }
        }
    }
    
    /*function getBoard(uint gameId) public view returns (bytes boardRep) { // apparently no string array can be returned yet in solidity
        string[boardSize][boardSize] storage board = games[gameId].board;
        string memory boardRepresentation;
        for(uint y = 0; y < boardSize; y++) {
            for(uint x = 0; x < boardSize; x++) {
                boardRepresentation = strConcat(boardRepresentation,board[y][x]);
            }
            boardRepresentation = strConcat(boardRepresentation,"\n");
        }
        return bytes(boardRepresentation);
        
    }*/
    
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

    function playMove(uint gameId, uint x, uint y) public returns (bool) {
        Game storage game = games[gameId];
        if (game.state == GameState.X_HAS_TURN
            && game.playerXAddr == msg.sender
        //&& game.moveCounter % 2 == 0   // host's turn?
            && game.board[y][x] == SquareState.EMPTY ) {        //equalStrings(game.board[y][x],"")) {
            game.board[y][x] = SquareState.X;
            game.moveCounter += 1;
            checkForWinner(x, y, gameId, game.playerXAddr);
            game.state = GameState.O_HAS_TURN;
            return true;
        }
        else if (game.state == GameState.O_HAS_TURN
                && game.playerOAddr == msg.sender
                //&& game.moveCounter % 2 == 1   // guest's turn?
                && game.board[y][x] == SquareState.EMPTY ) {    //equalStrings(game.board[y][x], "")) {
            game.board[y][x] = SquareState.O;
            game.moveCounter += 1;
            checkForWinner(x, y, gameId, game.playerOAddr);
            game.state = GameState.X_HAS_TURN;
            return true;
        }
        return false;
    }

    function checkForWinner(uint x, uint y, uint gameId, address currentPlayer) private {
        Game storage game = games[gameId];
        
        /*if(game.moveCounter < 2*boardSize -1) {           //what is reason for that?
            return;
        }*/

        SquareState[boardSize][boardSize] memory board = game.board;
        SquareState symbol = game.board[x][y];

        //check column
        for (uint i = 0; i < boardSize; i++) {
            if (board[i][i] != symbol)  {         //!equalStrings(board[i][i], symbol)) {
                break;
            }
            if(i == (boardSize -1)) {
                game.winnerAddr = currentPlayer;
                game.state = getGameState(symbol);
                return;
            }
        }

        //check row
        for (i = 0; i < boardSize; i++) {
            if(board[i][y] != symbol) {
                break;
            }

            if(i == (boardSize -1)) {
                game.winnerAddr = currentPlayer;
                game.state = getGameState(symbol);
                return;
            }
        }

        //check diagonal
        if(x == y) {
            for (i = 0; i < boardSize; i++) {
                if(board[i][i] != symbol) {
                    break;
                }
                if(i == (boardSize -1)) {
                    game.winnerAddr = currentPlayer;
                    game.state = getGameState(symbol);
                    return;
                }
            }
        }

        // check anti diagonal
        if(x + y == (boardSize -1)) {
            for (i = 0; i < boardSize; i++) {
                if(board[x][boardSize-1-1] != symbol) {            //!equalStrings(board[x][(boardSize-1) - 1], symbol)) {
                    break;
                }
                if(i == (boardSize -1)) {
                    game.winnerAddr = currentPlayer;
                    game.state = getGameState(symbol);
                    return;
                }
            }
        }
        
        //check for draw
        if (game.moveCounter == 2*boardSize) {
            game.state = GameState.DRAW;
        }
                
    }
    
    function getGameState(SquareState symbol) private returns (GameState state) {
        if (symbol == SquareState.X)
            return GameState.WINNER_X;
        else
            return GameState.WINNER_O;
    }
    
    function equalStrings (string a, string b) private pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
    

}
