// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PlebToHill is Ownable, ReentrancyGuard {
    uint256 public roundDuration;
    uint256 public extraDuration;
    uint256 public thresholdTime;

    struct Participant {
        uint256 participantId;
        address walletAddress;
        uint256 invested_amount;
        uint256 winnings;
        uint256 roundId;
        uint256 time;
    }

    struct Round {
        uint256 roundId;
        uint256 startTime;
        uint256 endTime;
        bool isLive;
    }
    address public poth_address;
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
    event TimeReset(uint256 roundId, uint256 endTime);

    /**
     * @notice Create new Round.Only owner can create a new round with 1 tPLS as contract balance.
     */
    function createRound() external onlyOwner {
        require(
            (roundDuration > 0 && extraDuration > 0 && thresholdTime > 0),
            "Round duration or extra duration  are not set."
        );
        require(
            address(this).balance >= 1e18,
            "Minimum contract balance should be 1 tPLS"
        );
        uint256 newRoundId = rounds.length + 1;

        if (rounds.length > 0)
            require(
                IsPreviousRoundFinished(),
                "Previous round is not finished yet"
            );

        RoundData[newRoundId] = Round({
            roundId: newRoundId,
            startTime: block.timestamp,
            endTime: block.timestamp + roundDuration,
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
        rounds[roundId - 1].isLive = false;

        if (participants[roundId].length == 1) {
            uint256 serviceFee = ((participants[roundId][0].invested_amount *
                2) * 5) / 100;
            uint256 prizeAmount = (participants[roundId][0].invested_amount *
                2) - serviceFee;

            (bool sent, ) = participants[roundId][0].walletAddress.call{
                value: prizeAmount
            }("");

            if (sent) {
                participants[roundId][0].winnings = prizeAmount;
                (bool success, ) = poth_address.call{value: serviceFee}("");
                require(success);
                emit WinningTransfered(
                    roundId,
                    participants[roundId][0].walletAddress,
                    participants[roundId][0].invested_amount,
                    participants[roundId][0].participantId,
                    prizeAmount
                );
            } else {
                (bool success, ) = poth_address.call{
                    value: (serviceFee + prizeAmount)
                }("");
                require(success);
            }
        }
        emit RoundFinished(roundId);
    }

    /**
    @notice Add a player to a live round. 
    @param roundId,Id of round to be partcipate.
     */
    function addParticipant(uint256 roundId) external payable nonReentrant {
        require(isCurrentRoundLive(roundId), "Round is not live");
        require(
            msg.value == getValueForNextParticipant(roundId),
            "Incorrect invested amount"
        );

        address _pleb = getCurrentPleb(roundId);

        require(
            !(_pleb == msg.sender),
            "You cannot deposit again until there is a new pleb"
        );

        uint256 newParticipantId = participants[roundId].length + 1;

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

        if (
            getRemainingTime(roundId) <= thresholdTime &&
            getRemainingTime(roundId) > 0
        ) {
            uint256 newTime = RoundData[roundId].endTime + extraDuration;
            RoundData[roundId].endTime = newTime;
            rounds[roundId - 1].endTime = newTime;
            emit TimeReset(roundId, newTime);
        }

        if (newParticipantId != 1) {
            uint256 serviceFee = ((participants[roundId][newParticipantId - 2]
                .invested_amount * 2) * 5) / 100;
            uint256 prizeAmount = (participants[roundId][newParticipantId - 2]
                .invested_amount * 2) - serviceFee;

            (bool sent, ) = participants[roundId][newParticipantId - 2]
                .walletAddress
                .call{value: prizeAmount}("");
            if (sent) {
                participants[roundId][newParticipantId - 2]
                    .winnings = prizeAmount;
                (bool success, ) = poth_address.call{value: serviceFee}("");
                require(success);
                emit WinningTransfered(
                    roundId,
                    participants[roundId][newParticipantId - 2].walletAddress,
                    participants[roundId][newParticipantId - 2].invested_amount,
                    participants[roundId][newParticipantId - 2].participantId,
                    prizeAmount
                );
            } else {
                (bool success, ) = poth_address.call{
                    value: (serviceFee + prizeAmount)
                }("");
                require(success);
            }
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
    @notice Set POTH(Pleb of the Hill) wallet address
    @param _pothwallet, new wallet address
     */

    function setPothWallet(address _pothwallet) external onlyOwner {
        require(_pothwallet != address(0), "Zero address not allowed");
        poth_address = _pothwallet;
    }

    /**
    @notice Set round duration
    @param _roundDurationInMinutes, round duration in minutes
     */
    function setRoundDuration(
        uint256 _roundDurationInMinutes
    ) external onlyOwner {
        require(
            _roundDurationInMinutes != 0,
            "Duration should be greater than 0"
        );
        roundDuration = _roundDurationInMinutes * 60;
    }

    /**
    @notice Set extra time duration
    @param _extraDurationInMinutes, extra time duration in minutes
     */

    function setExtraDuration(
        uint256 _extraDurationInMinutes
    ) external onlyOwner {
        require(
            _extraDurationInMinutes != 0,
            "Duration should be greater than 0"
        );
        extraDuration = _extraDurationInMinutes * 60;
    }

    /**
    @notice Set threshold time 
    @param _thresholdTime, threshold time after which extra duration will be added
     */

    function setThresoldTime(uint256 _thresholdTime) external onlyOwner {
        require(roundDuration > 0, "Set round duration first");

        require(
            _thresholdTime != 0 && _thresholdTime < roundDuration / 60,
            "Duration should be greater than 0 and roundDuration"
        );

        thresholdTime = _thresholdTime * 60;
    }

    /**
    @notice Get the loser participant data for a round.
    @param roundId,Round Id.
    @return id participant id.
    @return wallet participant wallet.
    @return amount_lose amount lose.
     */
    function getLoserData(
        uint256 roundId
    ) external view returns (uint256 id, address wallet, uint256 amount_lose) {
        if (
            participants[roundId].length == 1 ||
            participants[roundId].length == 0
        ) {
            id = 0;
            wallet = address(0);
            amount_lose = 0;
        } else {
            Participant memory participant = participants[roundId][
                participants[roundId].length - 1
            ];
            id = participant.participantId;
            wallet = participant.walletAddress;
            amount_lose = participant.invested_amount;
        }
    }

    /**
    @notice Get pleb of a round.
    @param roundId,Round Id.
    @return wallet participant wallet.
 
     */
    function getCurrentPleb(
        uint256 roundId
    ) public view returns (address wallet) {
        require(isCurrentRoundLive(roundId), "Round is not live");
        if (participants[roundId].length >= 1) {
            Participant memory participant = participants[roundId][
                participants[roundId].length - 1
            ];

            wallet = participant.walletAddress;
        } else {
            wallet = address(0);
        }
    }

    /**
    @notice Get all participant's detail in a round.
    @param roundId,Round Id.
    @return Participant array
     */
    function getAllParticipantOfRound(
        uint256 roundId
    ) external view returns (Participant[] memory) {
        return participants[roundId];
    }

    /**
     @notice Get Round data of a round
     @return round
     */
    function getRoundData(uint256 roundId) public view returns (Round memory) {
        return RoundData[roundId];
    }

    /**
    @notice Get all the rounds data from start to end indices
    @param start,start index
    @param end, end index
    @return Round array
     */
    function getAllRounds(
        uint256 start,
        uint256 end
    ) external view returns (Round[] memory) {
        require(end < rounds.length, "Invalid range");
        Round[] memory roundArray = new Round[]((end - start) + 1);
        for (uint256 i = 0; i <= (end - start); i++) {
            Round memory round = rounds[i + start];
            roundArray[i] = round;
        }

        return roundArray;
    }

    /**
    @notice Get the value of tPLS to be invested by the next player on a round.
    @param roundId,Round Id
    @return uint value in tPLS
     */
    function getValueForNextParticipant(
        uint256 roundId
    ) public view returns (uint256) {
        if (isCurrentRoundLive(roundId)) {
            uint256 totalParticipants = participants[roundId].length;

            return ((2 ** totalParticipants) * 1e18);
        } else {
            return 0;
        }
    }

    /**
    @notice Get current live round details 
    @return roundId
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
        if (rounds.length > 0) {
            Round memory round = RoundData[rounds.length];
            return (
                rounds.length,
                round.startTime,
                round.endTime,
                round.isLive
            );
        } else {
            return (0, 0, 0, false);
        }
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

    /**
     @notice Get the remaining time of a round
     @param roundId,Round Id
     @return remaining time
     */

    function getRemainingTime(uint256 roundId) public view returns (uint256) {
        Round memory roundData = getRoundData(roundId);

        if (block.timestamp < roundData.endTime)
            return roundData.endTime - block.timestamp;
        else return 0;
    }

    receive() external payable {}
}
