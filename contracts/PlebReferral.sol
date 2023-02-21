// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlebReferral is Ownable {
    IERC20 public token;
    address public plebContract;

    ///Mapping to store the referral relationship
    mapping(address => address) private referrals;

    ///Mapping to store the referral link
    mapping(address => string) private referralLinks;

    ///Mapping to store the referral code
    mapping(address => uint) private referralCodes;

    /// Event to emit when a referral reward is claimed
    event ClaimedReferralReward(
        address referrer,
        address player,
        uint256 amount
    );

    /// Event to emit when a referral link is generated
    event ReferralLinkGenerated(address referrer, string referralLink);

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
        address referrer = referrals[player];

        if (referrer != address(0)) {
            uint256 referralReward = (value * 5) / 100;
            if (token.balanceOf(address(this)) >= (referralReward * 2)) {
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
    function setReferrer(
        address referrer,
        address referee,
        uint _referralCode
    ) external onlyOwner {
        require(
            referrer != referee,
            "Referre and referrer address cannot be same"
        );

        require(
            referrals[referee] == address(0),
            "Referee already has a referrer"
        );

        require(
            keccak256(abi.encodePacked(referralLinks[referrer])) !=
                keccak256(abi.encodePacked("")),
            "Referrer does not have a referral link"
        );

        require(
            referralCodes[referrer] == _referralCode,
            "Referral code does not match"
        );

        referrals[referee] = referrer;
    }

    /**
     * @notice Set the pleb contract address
     * @param _plebContract Pleb contract address
     */
    function setPlebContract(address _plebContract) external onlyOwner {
        require(_plebContract != address(0), "zero address not allowed");
        plebContract = _plebContract;
    }

    /**
     * @notice Generate Referral link
     */
    function generateReferralLink() public payable {
        require(
            msg.value >= 1 ether,
            "You need to pay at least 1 TPLS to generate a referral link."
        );

        uint referralCode = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 1000000;

        string memory referralLink = string(
            abi.encodePacked(
                "https://plebofthehill.com/?referralCode=",
                referralCode
            )
        );

        referralLinks[msg.sender] = referralLink;
        referralCodes[msg.sender] = referralCode;

        emit ReferralLinkGenerated(msg.sender, referralLink);
    }

    /**
     * @notice Get the referral link
     * @param _address Referrer address
     * @return referral link
     */
    function getReferralLink(
        address _address
    ) external view returns (string memory) {
        return referralLinks[_address];
    }
}
