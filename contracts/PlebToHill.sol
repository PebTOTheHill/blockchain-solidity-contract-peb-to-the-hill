// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlebToHill is Ownable {
    struct Participant {
        uint256 participantId;
        address walletAddress;
        uint256 invested_amount;
        uint256 winnings;
        uint256 roundId;
        uint256 time;
    }

    struct Round {
        uint256 startTime;
        uint256 endTime;
        bool isLive;
    }

    mapping(uint256 => Round) public RoundData;
    Round[] internal rounds;
    mapping(uint256 => Participant[]) public participants;

    event RoundCreated(uint256 roundId, uint256 startTime, uint256 endTime);
    event ParticipantAdded(
        uint256 roundId,
        address walletAddress,
        uint256 invested_amount,
        uint256 participantId,
        uint256 time
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
            endTime: block.timestamp + 900,
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

        if (participants[roundId].length == 1) {
            payable(participants[roundId][0].walletAddress).transfer(
                2000000000000000000
            );
        }

        RoundData[roundId].isLive = false;
        rounds[roundId].isLive = false;
    }

    function addParticipant(uint256 roundId) external payable {
        require(isCurrentRoundLive(roundId), "Round is not live");
        require(
            msg.value == getValueForNextParticipant(roundId),
            "Incorrect invested amount"
        );

        uint256 newParticipantId = participants[roundId].length;

        participants[roundId].push(
            Participant({
                participantId: newParticipantId,
                walletAddress: msg.sender,
                invested_amount: msg.value,
                roundId: roundId,
                winnings: 0,
                time: block.timestamp
            })
        );

        if (newParticipantId > 0) {
            uint256 serviceFee = ((participants[roundId][newParticipantId - 1]
                .invested_amount * 2) * 5) / 100;
            uint256 prizeAmount = (participants[roundId][newParticipantId - 1]
                .invested_amount * 2) - serviceFee;

            payable(participants[roundId][newParticipantId - 1].walletAddress)
                .transfer(prizeAmount);
            participants[roundId][newParticipantId - 1].winnings += prizeAmount;
        }

        emit ParticipantAdded(
            roundId,
            msg.sender,
            msg.value,
            newParticipantId,
            block.timestamp
        );
    }

    function getValueForNextParticipant(uint256 roundId)
        public
        view
        returns (uint256)
    {
        require(isCurrentRoundLive(roundId), "Round is not live");
        uint256 totalParticipants = participants[roundId].length;
        return ((2**totalParticipants) * 1000000000000000000);
    }

    function getCurrentLiveRound()
        public
        view
        returns (
            uint256 roundId,
            uint256 startTime,
            uint256 endTime,
            bool isLive
        )
    {
        Round memory round = RoundData[rounds.length - 1];
        return (
            rounds.length - 1,
            round.startTime,
            round.endTime,
            round.isLive
        );
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

    function getAllParticipantOfRound(uint256 roundId)
        external
        view
        returns (Participant[] memory)
    {
        return participants[roundId];
    }

    function getAllRounds() external view returns (Round[] memory) {
        return rounds;
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
