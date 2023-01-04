// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface Token {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

contract PlebStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    Token public plebToken;

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
    uint256 constant STAKING_PERIOD = 1 days;

    mapping(uint256 => StakeDepositData) public stakers;
    mapping(address => StakeDepositData[]) public stakes;
    StakeDepositData[] public stakersData;

    event StakeAdded(
        uint256 stakeId,
        address wallet,
        uint256 amount,
        uint256 startDate,
        uint256 endDate
    );

    event ClaimedReward(uint256 stakeId, address wallet, uint256 amountClaimed);

    receive() external payable {}

    constructor(Token _plebToken) {
        plebToken = _plebToken;
    }

    modifier hasStaked(uint256 stakeId) {
        require(stakers[stakeId].activeStaked, "Stake is not active");
        require(
            msg.sender == stakers[stakeId].wallet,
            "Wrong wallet address,only staker of this stake can perform this operation"
        );
        _;
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount should be greater than 0");
        require(
            plebToken.allowance(msg.sender, address(this)) >= amount,
            "No allowance. Please grant pleb allowance"
        );
        require(
            plebToken.balanceOf(msg.sender) >= amount,
            "Cannot stake more than the balance"
        );

        plebToken.transferFrom(msg.sender, address(this), amount);

        uint256 newStakeId = stakersData.length + 1;
        stakers[newStakeId] = StakeDepositData({
            stakeId: newStakeId,
            wallet: msg.sender,
            amount: amount,
            startDate: block.timestamp,
            endDate: block.timestamp + STAKING_PERIOD,
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

    function unstake(uint256 stakeId) external nonReentrant hasStaked(stakeId) {
        require(
            hasCompletedStakingPeriod(stakeId),
            "Staking period is not over"
        );

        uint256 total_amount = stakers[stakeId].amount;

        stakers[stakeId].activeStaked = false;
        stakers[stakeId].unstakedStatus = 1;
        stakersData[stakeId].activeStaked = false;
        stakersData[stakeId].unstakedStatus = 1;

        plebToken.transfer(stakers[stakeId].wallet, total_amount);
    }

    function accumulateReward() external payable {
        if (msg.value > 0) {
            accHedronRewardRate = accHedronRewardRate.add(
                msg.value.mul(1e18).div(totalActiveStakes())
            );
        }
    }

    function hasCompletedStakingPeriod(
        uint256 stakeId
    ) internal view returns (bool) {
        if (block.timestamp > stakers[stakeId].endDate) {
            return true;
        } else {
            return false;
        }
    }

    function totalActiveStakes() public view returns (uint256 totalStakes) {
        for (uint256 i = 0; i < stakersData.length; i++) {
            if (stakersData[i].activeStaked) {
                if (!hasCompletedStakingPeriod(stakersData[i].stakeId)) {
                    totalStakes = totalStakes.add(stakersData[i].amount);
                }
            }
        }

        return totalStakes;
    }

    function claimReward(
        uint256 stakeId
    ) public nonReentrant hasStaked(stakeId) {
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

            emit ClaimedReward(stakeId, stakers[stakeId].wallet, reward);
        }
    }

    function calculateRewards(
        uint256 stakeId
    ) public view returns (uint256 reward) {
        StakeDepositData memory s = stakers[stakeId];
        reward = s.amount.mul(accHedronRewardRate).div(1e18).sub(s.rewardDebt);
    }
}
