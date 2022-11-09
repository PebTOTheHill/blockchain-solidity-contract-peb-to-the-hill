// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlebToHill is Ownable {
    struct Participant {
        uint256 participantId;
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
    event ParticipantAdded(
        uint256 roundId,
        address walletAddress,
        uint256 invested_amount,
        uint256 participantId
    );

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
            endTime: block.timestamp + 10800,
            isLive: true
        });

        rounds.push(RoundData[newRoundId]);
        emit RoundCreated(
            newRoundId,
            RoundData[newRoundId].startTime,
            RoundData[newRoundId].endTime
        );
    }

    function endRound(uint256 roundId) external onlyOwner {
        require(!isCurrentRoundLive(roundId), "Round is  live");

        RoundData[roundId].isLive = false;
        rounds[roundId].isLive = false;
    }

    function addParticipant(uint256 roundId) external payable {
        require(isCurrentRoundLive(roundId), "Round is not live");
        require(
            msg.value == getValueForNextParticipant(roundId),
            "Incorrect invested amount"
        );
        require(
            !isUserAvailable(roundId, msg.sender),
            "User already entered for the round"
        );

        uint256 newParticipantId = participants[roundId].length;

        participants[roundId].push(
            Participant({
                participantId: newParticipantId,
                walletAddress: msg.sender,
                invested_amount: msg.value,
                roundId: roundId
            })
        );
        emit ParticipantAdded(roundId, msg.sender, msg.value, newParticipantId);
    }

    function isUserAvailable(uint256 roundId, address wallet)
        internal
        view
        returns (bool)
    {
        bool isAvailable;
        for (uint256 i = 0; i < participants[roundId].length; i++) {
            if (participants[roundId][i].walletAddress == wallet) {
                isAvailable = true;
                break;
            }
        }

        return isAvailable;
    }

    function getValueForNextParticipant(uint256 roundId)
        public
        view
        returns (uint256)
    {
        uint256 totalParticipants = participants[roundId].length;
        return ((2**totalParticipants) * 1000000000000000000);
    }

    function IsPreviousRoundFinished() internal view returns (bool) {
        bool finished;
        if (
            rounds[rounds.length - 1].endTime < block.timestamp &&
            !(rounds[rounds.length - 1].isLive)
        ) {
            finished = true;
        }

        return finished;
    }

    function isCurrentRoundLive(uint256 roundId) internal view returns (bool) {
        bool isLive;
        if (
            RoundData[roundId].endTime >= block.timestamp &&
            RoundData[roundId].isLive
        ) isLive = true;

        return isLive;
    }

    receive() external payable {}
}
