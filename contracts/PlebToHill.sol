// SPDX-License-Identifier: NONE
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStake {
    function accumulateReward() external payable returns (bool success);
}

interface IReferral {
    function distributeReferredAmount(address player, uint256 value) external;
}

contract PlebToHill is Ownable, ReentrancyGuard {
    IERC20 public plebToken;
    IStake public plebStakeAddress;
    IReferral public plebReferralContractAddress;
    uint256 public plebTokens;
    address public pothWallet;

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

    mapping(uint256 => Round) private roundData;
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
    event PlebTokenTransfered(uint256 id, address transferedTo, uint256 amount);

    constructor(
        address _plebToken,
        address _plebStakeAddress,
        address _plebReferralContract
    ) {
        plebToken = IERC20(_plebToken);
        plebStakeAddress = IStake(_plebStakeAddress);
        plebReferralContractAddress = IReferral(_plebReferralContract);
    }

    receive() external payable {}

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

        roundData[newRoundId] = Round({
            roundId: newRoundId,
            startTime: block.timestamp,
            endTime: block.timestamp + roundDuration,
            isLive: true
        });

        rounds.push(roundData[newRoundId]);
        emit RoundCreated(
            newRoundId,
            roundData[newRoundId].startTime,
            roundData[newRoundId].endTime
        );
    }

    /**
    @notice End a live round once the round duration completed 
    @param roundId,Id of round to be end.
     */
    function endRound(uint256 roundId) external onlyOwner {
        require(!isCurrentRoundLive(roundId), "Round is  live");
        require(roundData[roundId].isLive, "Round already finished");
        roundData[roundId].isLive = false;
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
                transferAmounts(serviceFee);

                emit WinningTransfered(
                    roundId,
                    participants[roundId][0].walletAddress,
                    participants[roundId][0].invested_amount,
                    participants[roundId][0].participantId,
                    prizeAmount
                );
            } else {
                transferAmounts(prizeAmount + serviceFee);
            }
        }

        (uint id, address wallet, uint amount_lose) = getLoserData(roundId);

        if (plebTokens >= amount_lose && wallet != address(0)) {
            require(
                plebToken.transfer(wallet, amount_lose),
                "Token not transfered"
            );
            plebTokens -= amount_lose;
            emit PlebTokenTransfered(id, wallet, amount_lose);
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
            uint256 newTime = roundData[roundId].endTime + extraDuration;
            roundData[roundId].endTime = newTime;
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
                transferAmounts(serviceFee);
                emit WinningTransfered(
                    roundId,
                    participants[roundId][newParticipantId - 2].walletAddress,
                    participants[roundId][newParticipantId - 2].invested_amount,
                    participants[roundId][newParticipantId - 2].participantId,
                    prizeAmount
                );
            } else {
                transferAmounts(prizeAmount + serviceFee);
            }
        }

        plebReferralContractAddress.distributeReferredAmount(
            msg.sender,
            msg.value
        );

        emit ParticipantAdded(
            roundId,
            msg.sender,
            msg.value,
            newParticipantId,
            block.timestamp
        );
    }

    /**
     * @notice Set POTH wallet to get 50% of the commission
     * @param pothWalletAddress New wallet address
     */

    function setPothWallet(address pothWalletAddress) external onlyOwner {
        require(pothWalletAddress != address(0), "Zero address is not allowed");
        pothWallet = pothWalletAddress;
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
     * @notice
     */
    function updateStakingContractAddress(
        address newStakeAddress
    ) external onlyOwner {
        require(newStakeAddress != address(0), "Zero address is not allowed");
        plebStakeAddress = IStake(newStakeAddress);
    }

    /**
     * @notice Transfer Pleb Tokens for distribution to this contract
     * @param _amount Amount of pleb tokens
     */
    function transferPleb(uint256 _amount) external onlyOwner {
        plebTokens = plebTokens + _amount;
        require(plebToken.transferFrom(msg.sender, address(this), _amount));
    }

    function updateReferralContract(
        address _plebReferralContract
    ) external onlyOwner {
        require(
            _plebReferralContract != address(0),
            "Zero address not allowed"
        );
        plebReferralContractAddress = IReferral(_plebReferralContract);
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
    @notice Get the loser participant data for a round.
    @param roundId,Round Id.
    @return id participant id.
    @return wallet participant wallet.
    @return amount_lose amount lose.
     */
    function getLoserData(
        uint256 roundId
    ) public view returns (uint256 id, address wallet, uint256 amount_lose) {
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
     @notice Get Round data of a round
     @return round
     */
    function getRoundData(uint256 roundId) public view returns (Round memory) {
        return roundData[roundId];
    }

    /**
     @notice Get the remaining time of a round
     @param roundId,Round Id
     @return remaining time+
     */

    function getRemainingTime(uint256 roundId) public view returns (uint256) {
        Round memory round = getRoundData(roundId);

        if (block.timestamp < round.endTime)
            return round.endTime - block.timestamp;
        else return 0;
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
            Round memory round = roundData[rounds.length];
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
        bool finished = false;
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
            roundData[roundId].endTime >= block.timestamp &&
            roundData[roundId].isLive
        ) isLive = true;

        return isLive;
    }

    /**
     * @notice Internal function to transfer amounts to stake contract and Poth wallet
     * @param _amount total amount
     */

    function transferAmounts(uint256 _amount) internal {
        uint256 rewardShare = _amount / 2;

        bool success = plebStakeAddress.accumulateReward{value: rewardShare}();
        require(success, "Reward share transfer failed");

        (bool success2, ) = pothWallet.call{value: (_amount - rewardShare)}("");
        require(success2, "Poth wallet share transfer failed");
    }
}
