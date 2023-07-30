// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Token is IERC20 {
    function burnTokens(uint256 amount) external;
}

contract PlebStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    Token public plebToken;
    uint256 internal lauchTime = block.timestamp;

    struct StakeDepositData {
        uint256 stakeId;
        address wallet;
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        uint256 claimedRewards;
        uint256 rewardDebt;
        uint256 unstakedStatus;
        bool activeStaked;
    }

    uint256 public accHedronRewardRate;
    uint256 public rewardCollected;
    uint256 public stakingPeriod = 30 days;

    mapping(uint256 => StakeDepositData) public stakers;
    mapping(address => StakeDepositData[]) public stakes;
    mapping(uint256 => uint256) public dayToRatioMapping;
    StakeDepositData[] public stakersData;

    event StakeAdded(
        uint256 stakeId,
        address wallet,
        uint256 amount,
        uint256 startDate,
        uint256 endDate
    );

    event StakeRemoved(
        uint256 stakeId,
        address wallet,
        uint256 rewardClaimed,
        uint256 tokenClaimed
    );

    event ClaimedReward(uint256 stakeId, address wallet, uint256 rewardClaimed);
    event emergencyEndStaked(
        uint256 stakeId,
        address wallet,
        uint256 rewardClaimed,
        uint256 tokenClaimed
    );

    event RewardDistributed(uint amount);

    modifier hasStaked(uint256 stakeId) {
        require(stakers[stakeId].activeStaked, "Stake is not active");
        require(
            msg.sender == stakers[stakeId].wallet,
            "Wrong wallet address,only staker of this stake can perform this operation"
        );
        _;
    }

    constructor(address _plebToken) {
        plebToken = Token(_plebToken);
    }

    receive() external payable {}

    /* ======== USER FUNCTIONS ======== */

    /**
     * @notice To stake hedron
     * @param amount uint256, Amount of pleb in 18 decimal(WEI)
     */

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount should be greater than 0");

        require(
            plebToken.balanceOf(msg.sender) >= amount,
            "Cannot stake more than the balance"
        );

        require(
            plebToken.transferFrom(msg.sender, address(this), amount),
            "Staking failed"
        );

        uint256 newStakeId = stakersData.length + 1;
        stakers[newStakeId] = StakeDepositData({
            stakeId: newStakeId,
            wallet: msg.sender,
            amount: amount,
            startDate: block.timestamp,
            endDate: block.timestamp + stakingPeriod,
            claimedRewards: 0,
            rewardDebt: amount.mul(accHedronRewardRate).div(1e18),
            unstakedStatus: 0, //0 -> default, 1 -> Unstaked, 2 -> Emergency end stake
            activeStaked: true
        });

        stakes[msg.sender].push(stakers[newStakeId]);
        stakersData.push(stakers[newStakeId]);

        assert(stakersData[newStakeId - 1].wallet == msg.sender);

        emit StakeAdded(
            newStakeId,
            msg.sender,
            amount,
            stakersData[newStakeId - 1].startDate,
            stakersData[newStakeId - 1].endDate
        );
    }

    /**
     * @notice To unstake pleb once staking period is completed
     * @param stakeId uint256, Stake Id
     */

    function unstake(uint256 stakeId) external nonReentrant hasStaked(stakeId) {
        require(
            hasCompletedStakingPeriod(stakeId),
            "Staking period is not over"
        );

        uint256 reward = calculateRewards(stakeId);
        if (reward > 0) {
            (bool success, ) = stakers[stakeId].wallet.call{value: reward}("");
            require(success, "Reward tranfer failed");
        }
        uint256 total_amount = stakers[stakeId].amount;

        stakers[stakeId].activeStaked = false;
        stakers[stakeId].unstakedStatus = 1;
        stakersData[stakeId - 1].activeStaked = false;
        stakersData[stakeId - 1].unstakedStatus = 1;

        uint256 index = getUserStakeIndex(msg.sender, stakeId);

        stakes[msg.sender][index].activeStaked = false;
        stakes[msg.sender][index].unstakedStatus = 1;

        uint256 daysAfterPeriod = getDaysPass(stakeId);

        if (daysAfterPeriod <= 5) {
            require(
                plebToken.transfer(stakers[stakeId].wallet, total_amount),
                "Unstaking failed"
            );
            emit StakeRemoved(
                stakeId,
                stakers[stakeId].wallet,
                reward,
                total_amount
            );
        } else {
            plebToken.burnTokens(total_amount);
            emit StakeRemoved(stakeId, stakers[stakeId].wallet, reward, 0);
        }
    }

    /**
     * @notice To end the stake before the staking period is over. User will have to pay 50% of the staked  amount as penalty
     * @param stakeId uint256, Stake Id
     */
    function emergencyEndStake(
        uint256 stakeId
    ) external nonReentrant hasStaked(stakeId) {
        require(
            !hasCompletedStakingPeriod(stakeId),
            "Staking period is over cannot ESS now"
        );
        uint256 reward = calculateRewards(stakeId);
        if (reward > 0) {
            (bool success, ) = stakers[stakeId].wallet.call{value: reward}("");
            require(success, "Reward tranfer failed");
        }

        uint256 pleb = stakers[stakeId].amount.div(2);

        require(
            plebToken.transfer(stakers[stakeId].wallet, pleb),
            "Unstaking failed"
        );

        stakers[stakeId].activeStaked = false;
        stakers[stakeId].unstakedStatus = 2;

        stakersData[stakeId - 1].activeStaked = false;
        stakersData[stakeId - 1].unstakedStatus = 2;

        uint256 index = getUserStakeIndex(msg.sender, stakeId);

        stakes[msg.sender][index].activeStaked = false;
        stakes[msg.sender][index].unstakedStatus = 2;

        plebToken.burnTokens(stakers[stakeId].amount.sub(pleb));
        emit emergencyEndStaked(stakeId, stakers[stakeId].wallet, reward, pleb);
    }

    /** 
    * @notice Collect reward from pleb of the hill contract
    * @return success
    
    */
    function accumulateReward() external payable returns (bool success) {
        if (msg.value > 0) {
            rewardCollected += msg.value;
            success = true;
        }
    }

    /**
     * @notice Update the reward rate with the collected reward.
     */

    function distributeReward() external {
        uint256 reward = rewardCollected;
        require(rewardCollected > 0, "No reward available.");
        require(totalActiveStakes() > 0, "No active stakers");
        accHedronRewardRate = accHedronRewardRate.add(
            rewardCollected.mul(1e18).div(totalActiveStakes())
        );

        rewardCollected = 0;
        dayToRatioMapping[currentDay()] = accHedronRewardRate;
        emit RewardDistributed(reward);
    }

    /*
     *@notice To get all the stakes stake by a given wallet address
     *@param wallet address, Wallet address
     *@return StakeDepositData[]
     */
    function getStakes(
        address wallet
    ) external view returns (StakeDepositData[] memory) {
        return stakes[wallet];
    }

    /*
     *@notice To update staking period.
     *@param newStakingPeriodInDays uint256, No. of days
     */
    function updateStakingPeriod(
        uint256 newStakingPeriodInDays
    ) external onlyOwner {
        require(
            newStakingPeriodInDays != stakingPeriod,
            "Add a different staking period"
        );

        stakingPeriod = newStakingPeriodInDays * 86400; //test this implementation
    }

    /*
     *@notice To get total active staked hedron amount at current time
     *@return uint(totalStakes)
     */
    function totalActiveStakes() public view returns (uint256 totalStakes) {
        if (stakersData.length == 0) {
            totalStakes = 0;
        } else {
            for (
                uint256 i = findIndex(stakersData, block.timestamp);
                i < stakersData.length;
                i++
            ) {
                if (stakersData[i].activeStaked) {
                    if (!hasCompletedStakingPeriod(stakersData[i].stakeId)) {
                        totalStakes = totalStakes.add(stakersData[i].amount);
                    }
                }
            }
        }

        return totalStakes;
    }

    /*
     *@notice To claim the reward. User can claim reward at any point of time before unstake or emergency end stake
     *@param stakeId uint256, Stake Id
     */
    function claimReward(
        uint256 stakeId
    ) external nonReentrant hasStaked(stakeId) {
        require(
            block.timestamp <
                (stakers[stakeId].endDate).add(getDaysPass(stakeId))
        );

        uint256 reward = calculateRewards(stakeId);
        require(reward > 0, "No reward available to claim");

        (bool sent, ) = stakers[stakeId].wallet.call{value: reward}("");

        if (sent) {
            stakers[stakeId].claimedRewards = stakers[stakeId]
                .claimedRewards
                .add(reward);
            stakers[stakeId].rewardDebt = stakers[stakeId].rewardDebt.add(
                reward
            );

            stakersData[stakeId - 1].claimedRewards = stakersData[stakeId - 1]
                .claimedRewards
                .add(reward);
            stakersData[stakeId - 1].rewardDebt = stakersData[stakeId - 1]
                .rewardDebt
                .add(reward);

            uint256 index = getUserStakeIndex(msg.sender, stakeId);

            stakes[msg.sender][index].claimedRewards = stakes[msg.sender][index]
                .claimedRewards
                .add(reward);
            stakes[msg.sender][index].rewardDebt = stakes[msg.sender][index]
                .rewardDebt
                .add(reward);

            emit ClaimedReward(stakeId, stakers[stakeId].wallet, reward);
        }
    }

    /*
     *@notice To calculate the reward for a given stake
     *@param stakeId uint256, Stake Id
     *@return uint256(reward)
     */
    function calculateRewards(uint256 stakeId) public view returns (uint256) {
        uint256 reward;
        StakeDepositData memory s = stakers[stakeId];
        require(s.activeStaked, "Stake is not active");

        if (hasCompletedStakingPeriod(stakeId)) {
            uint256 endDate = ((s.endDate - s.startDate).div(1 days)).add(
                (s.startDate - lauchTime).div(1 days)
            );
            for (uint256 i = endDate; i > 0; i--) {
                if (dayToRatioMapping[i] > 0) {
                    reward = s.amount.mul(dayToRatioMapping[i]).div(1e18).sub(
                        s.rewardDebt
                    );
                    break;
                }
            }
        } else {
            reward = s.amount.mul(accHedronRewardRate).div(1e18).sub(
                s.rewardDebt
            );
        }

        return reward;
    }

    /*
     *@notice To get the current Day of the contract
     *@return uint256(currentDay)
     */
    function currentDay() public view returns (uint256) {
        return _currentDay();
    }

    /**
     * @notice Get days pass after staking period
     * @param stakeId ID of stake
     * @return days , days pass after staking period
     */

    function getDaysPass(uint256 stakeId) internal view returns (uint256) {
        if (block.timestamp < stakers[stakeId].endDate) return 0;
        return (block.timestamp.sub(stakers[stakeId].endDate)).div(1 days);
    }

    /*
     *@notice Internal function to get the current Day of the contract
     *@return uint256(currentDay)
     */
    function _currentDay() internal view returns (uint256) {
        return (block.timestamp.sub(lauchTime)).div(1 days).add(1);
    }

    /**
     *@notice To check if the staking period is over for a given stake
     *@param stakeId uint256, Stake Id
     *@return bool
     */
    function hasCompletedStakingPeriod(
        uint256 stakeId
    ) internal view returns (bool) {
        if (block.timestamp > stakers[stakeId].endDate) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Get index of stake for an user address
     */
    function getUserStakeIndex(
        address _wallet,
        uint256 stakeId
    ) internal view returns (uint256 index) {
        StakeDepositData[] memory s = stakes[_wallet];

        for (uint i = 0; i < s.length; i++) {
            if (s[i].stakeId == stakeId) {
                index = i;
                break;
            }
        }
    }

    /**
     * @notice Internal function to find the index
     * @param arr Stake deposit data array
     * @param value current timestamp
     */

    function findIndex(
        StakeDepositData[] memory arr,
        uint value
    ) internal pure returns (uint) {
        uint min = 0;
        uint max = arr.length - 1;
        uint index = arr.length;

        while (min <= max) {
            uint mid = (min + max) / 2;
            if (arr[mid].endDate > value) {
                if (mid == 0 || arr[mid - 1].endDate <= value) {
                    index = mid;
                    break;
                }
                max = mid - 1;
            } else {
                min = mid + 1;
            }
        }
        return index;
    }
}
