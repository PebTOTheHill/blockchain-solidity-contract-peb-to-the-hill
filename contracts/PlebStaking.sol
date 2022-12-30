// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPlebToken{
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract PlebStaking is Ownable,ReentrancyGuard{

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


 function stake(uint256 amount) external nonReentrant returns (uint256) {
        require(amount > 0, "Amount should be greater than 0");
        require(
            IHedron(hdrnToken).allowance(msg.sender, address(this)) >= amount,
            "No allowance. Please grant hedron allowance"
        );
        require(
            IHedron(hdrnToken).balanceOf(msg.sender) >= amount,
            "Cannot stake more than the balance"
        );

        IHedron(hdrnToken).transferFrom(msg.sender, address(this), amount);

        uint256 newStakeId = stakersData.length;
        stakers[newStakeId] = StakeDepositData({
            stakeId: newStakeId,
            wallet: msg.sender,
            amount: amount,
            startDate: block.timestamp,
            endDate: block.timestamp + stakingPeriod,
            claimedRewards: 0,
            rewardDebt: amount.mul(accHedronRewardRate).div(1e9),
            unstakedStatus: 0, //0 -> default, 1 -> Unstaked, 2 -> Emergency end stake
            activeStaked: true
        });

        stakes[msg.sender].push(stakers[newStakeId]);
        stakersData.push(stakers[newStakeId]);

        assert(stakersData[newStakeId].wallet == msg.sender);
        totalHedronStaked = totalHedronStaked.add(amount);

        emit stakeAdded(
            newStakeId,
            msg.sender,
            amount,
            stakersData[newStakeId].startDate,
            stakersData[newStakeId].endDate
        );


}

}