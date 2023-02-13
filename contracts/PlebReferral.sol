// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlebReferral is Ownable {
    IERC20 public token;
    address public plebContract;

    /// User struct
    struct User {
        bool claimed;
        address referred_by;
    }

    ///Mapping to store the referral relationship
    mapping(address => User) public referrals;

    /// Event to emit when a referral reward is claimed
    event ClaimedReferralReward(
        address referrer,
        address player,
        uint256 amount
    );

    /// Modifier to check if calling contract is plebToHill.
    modifier isPlebContract(address _contract) {
        require(
            _contract == plebContract,
            "Only Pleb Contract can call this method"
        );
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
     * @notice Distribute the referred amount
     * @param player Player address
     * @param value  Playing amount
     */
    function distributeReferredAmount(
        address player,
        uint256 value
    ) external isPlebContract(msg.sender) {
        address referrer = referrals[player].referred_by;

        if (referrer != address(0) && !referrals[player].claimed) {
            uint256 referralReward = (value * 5) / 100;
            if (token.balanceOf(address(this)) >= (referralReward * 2)) {
                referrals[player].claimed = true;
                token.transfer(referrer, referralReward);
                token.transfer(player, referralReward);

                emit ClaimedReferralReward(referrer, player, referralReward);
            }
        }
    }

    /**
     * @notice Set referrer address
     * @param referrer Referrer address
     * @param referee  Referee address
     */
    function setReferrer(address referrer, address referee) external {
        require(
            referrer != referee,
            "Referre and referrer address cannot be same"
        );

        referrals[referee] = User({claimed: false, referred_by: referrer});
    }

    /**
     * @notice Set the pleb contract address
     * @param _plebContract Pleb contract address
     */
    function setPlebContract(address _plebContract) external onlyOwner {
        require(_plebContract != address(0), "zero address not allowed");
        plebContract = _plebContract;
    }
}
