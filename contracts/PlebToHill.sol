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

    mapping(uint256 => Round) private RoundData;
    Round[] private rounds;
    mapping(uint256 => Participant[]) private participants;

    event RoundCreated(uint256 roundId, uint256 startTime, uint256 endTime);
    event ParticipantAdded(
        uint256 roundId,
        address walletAddress,
        uint256 invested_amount,
        uint256 participantId,
        uint256 time
    );
    event WinningTransfered(
        uint256 roundId,
        address walletAddress,
        uint256 invested_amount,
        uint256 participantId,
        uint256 winnings
    );
    event RoundFinished(uint256 roundId);

    /**
     * @notice Create new Round.Only owner can create a new round with 1 tPLS as contract balance.
     */
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
            endTime: block.timestamp + 300,
            isLive: true
        });

        rounds.push(RoundData[newRoundId]);
        emit RoundCreated(
            newRoundId,
            RoundData[newRoundId].startTime,
            RoundData[newRoundId].endTime
        );
    }

    /**
    @notice End a live round once the round duration completed 
    @param roundId,Id of round to be end.
     */
    function endRound(uint256 roundId) external onlyOwner {
        require(!isCurrentRoundLive(roundId), "Round is  live");
        require(RoundData[roundId].isLive, "Round already finished");
        RoundData[roundId].isLive = false;
        rounds[roundId].isLive = false;

        if (participants[roundId].length == 1) {
            uint256 serviceFee = ((participants[roundId][0].invested_amount *
                2) * 5) / 100;
            uint256 prizeAmount = (participants[roundId][0].invested_amount *
                2) - serviceFee;
            participants[roundId][0].winnings = prizeAmount;
            payable(participants[roundId][0].walletAddress).transfer(
                prizeAmount
            );
            emit WinningTransfered(
                roundId,
                participants[roundId][0].walletAddress,
                participants[roundId][0].invested_amount,
                participants[roundId][0].participantId,
                prizeAmount
            );
        }
        emit RoundFinished(roundId);
    }

    /**
    @notice Add a player to a live round. 
    @param roundId,Id of round to be partcipate.
     */
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

        if (newParticipantId != 0) {
            uint256 serviceFee = ((participants[roundId][newParticipantId - 1]
                .invested_amount * 2) * 5) / 100;
            uint256 prizeAmount = (participants[roundId][newParticipantId - 1]
                .invested_amount * 2) - serviceFee;
            participants[roundId][newParticipantId - 1].winnings = prizeAmount;

            payable(participants[roundId][newParticipantId - 1].walletAddress)
                .transfer(prizeAmount);

            emit WinningTransfered(
                roundId,
                participants[roundId][newParticipantId - 1].walletAddress,
                participants[roundId][newParticipantId - 1].invested_amount,
                participants[roundId][newParticipantId - 1].participantId,
                prizeAmount
            );
        }

        emit ParticipantAdded(
            roundId,
            msg.sender,
            msg.value,
            newParticipantId,
            block.timestamp
        );
    }

    /**
    @notice Get the loser participant data for a round.
    @param roundId,Round Id.
    @return id participant id.
    @return wallet participant wallet
    @return amount_lose amount lose.
     */

    function getLoserData(uint256 roundId)
        external
        view
        returns (
            uint256 id,
            address wallet,
            uint256 amount_lose
        )
    {
        require(participants[roundId].length > 1, "No loser in this round.");
        Participant memory participant = participants[roundId][
            participants[roundId].length - 1
        ];
        id = participant.participantId;
        wallet = participant.walletAddress;
        amount_lose = participant.invested_amount;
    }

    /**
    @notice Get all participant's detail in a round.
    @param roundId,Round Id.
    @return Participant array
     */
    function getAllParticipantOfRound(uint256 roundId)
        external
        view
        returns (Participant[] memory)
    {
        return participants[roundId];
    }

    /**
    @notice Get the details of a single round.
    @param roundId, Round id
    @return Round
     */

    function getRoundData(uint256 roundId)
        external
        view
        returns (Round memory)
    {
        return RoundData[roundId];
    }

    /**
    @notice Get all the rounds data
    @return Round array
     */
    function getAllRounds() external view returns (Round[] memory) {
        return rounds;
    }

    /**
    @notice Get the value of tPLS to be invested by the next player on a round.
    @param roundId,Round Id
    @return uint value in tPLS
     */
    function getValueForNextParticipant(uint256 roundId)
        public
        view
        returns (uint256)
    {
        require(isCurrentRoundLive(roundId), "Round is not live");
        uint256 totalParticipants = participants[roundId].length;
        return ((2**totalParticipants) * 1000000000000000000);
    }

    /**
    @notice Get current live round details 
    @return roundId round id
    @return startTime round start time
    @return endTime round end time
    @return isLive check if round is live
     */
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

    /**
    @notice Check if the previous round is finished.
    @return finished
     */
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

    /**
    @notice Check if the current round is live.
    @return isLive
     */
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
