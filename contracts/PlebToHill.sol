// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlebToHill is Ownable {
    struct Participant {
        address walletAddress;
        uint256 invested_amount;
        uint256 roundId;
    }

    struct Round {
        uint256 startTime;
        uint256 endTime;
        bool isLive;
    }

    mapping(uint256 => Round) public RoundData;
    Round[] public rounds;
    mapping(uint256 => Participant[]) public participants;

    event RoundCreated(uint256 roundId, uint256 startTime, uint256 endTime);

    function createRound() external onlyOwner {
        require(
            address(this).balance >= 1000000000000000000,
            "Minimum contract balance should be 1 tPLS"
        );
        uint256 newRoundId = rounds.length;

        if (rounds.length > 0)
            require(
                IsPreviousRoundFinished(),
                "Previous round is not finished yet"
            );

        RoundData[newRoundId] = Round({
            startTime: block.timestamp,
            endTime: block.timestamp + 1800,
            isLive: true
        });

        rounds.push(RoundData[newRoundId]);
        emit RoundCreated(
            newRoundId,
            RoundData[newRoundId].startTime,
            RoundData[newRoundId].endTime
        );
    }

    function IsPreviousRoundFinished() internal view returns (bool) {
        bool finished;
        if (rounds[rounds.length - 1].endTime < block.timestamp) {
            finished = true;
        }

        return finished;
    }

    receive() external payable {}
}
