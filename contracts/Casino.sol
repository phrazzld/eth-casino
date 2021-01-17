pragma solidity 0.5.16;

contract Casino {
    address public owner;
    uint256 public minimumBet;
    uint256 public totalBet;
    uint256 public numberOfBets;
    uint256 public maxAmountOfBets = 100;
    address[] public players;

    struct Player {
        uint256 amountBet;
        uint256 numberSelected;
    }

    // the address of the player and => the user info
    mapping(address => Player) public playerInfo;

    // contract constructor
    constructor(uint256 _minimumBet) public {
        owner = msg.sender;
        if (_minimumBet != 0) minimumBet = _minimumBet;
    }

    function kill() public {
        if (msg.sender == owner) selfdestruct(msg.sender);
    }

    function checkPlayerExists(address player) public view returns(bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) return true;
        }
        return false;
    }

    // bet on a number between 1 and 10 (inclusive)
    function bet(uint256 numberSelected) public payable {
        require(!checkPlayerExists(msg.sender));
        require(numberSelected >= 1 && numberSelected <= 10);
        require(msg.value >= minimumBet);

        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].numberSelected = numberSelected;
        numberOfBets++;
        players.push(msg.sender);
        totalBet += msg.value;

        if (numberOfBets >= maxAmountOfBets) generateNumberWinner();
    }

    // generate the winning number
    // TODO: refactor to use Chainlink VRF
    function generateNumberWinner() public {
        uint256 numberGenerated = block.number % 10 + 1;
        distributePrizes(numberGenerated);
    }

    // send eth to winners
    function distributePrizes(uint256 numberWinner) public {
        address payable[100] memory winners;
        uint256 count = 0;

        for (uint256 i = 0; i < players.length; i++) {
            address playerAddress = players[i];
            if (playerInfo[playerAddress].numberSelected == numberWinner) {
                // from Solidity docs:
                // "Implicit conversions from address payable to address are allowed,
                // whereas conversions from address to address payable are not possible
                // (the only way to perform such a conversion is by using an intermediate
                // conversion to uint160)"
                winners[count] = address(uint160(playerAddress));
                count++;
            }
            // delete each player
            delete playerInfo[playerAddress];
        }

        uint256 winnerEtherAmount = totalBet / winners.length;

        for (uint256 j = 0; j < count; j++) {
            if (winners[j] != address(0)) {
                winners[j].transfer(winnerEtherAmount);
            }
        }

        resetData();
    }

    function resetData() internal {
        players.length = 0;
        totalBet = 0;
        numberOfBets = 0;
    }

    // fallback function
    function() payable external {}
}
