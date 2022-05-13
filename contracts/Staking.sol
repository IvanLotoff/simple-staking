pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "hardhat/console.sol";


contract Staking is ERC20, Ownable, ERC20Burnable{
    uint256 constant secondsInOneDay = 60 * 60 * 24;
    
    struct staker {
        uint256 value;
        uint256 stakeStartedDate;
    }

    mapping(address => staker) internal stakerByAddress;

    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

     /**
     * @dev Modifier that reverts if staking period is not over
     */
    modifier afterStakePeriod() {
        require(showUserDaysRemaining() == 0, "stake period is not over");
        _;
    }

    /**
     * @dev function that creates stake
     */
    function createStake(uint256 _stake) public {
        require(balanceOf(msg.sender) >= _stake, "low balance");
        require(stakerByAddress[msg.sender].value == 0, "Already staked");
        stakerByAddress[msg.sender].value = _stake;
        stakerByAddress[msg.sender].stakeStartedDate = block.timestamp;
        burn(_stake);
    }

     /**
     * @dev shows how much money a user is staking
     */
    function showUserStakeAmount() public view returns (uint256) {
        return stakerByAddress[msg.sender].value;
    }

     /**
     * @dev shows how many days is yet to stake, if the stake period is over
     * it returns 0
     */
    function showUserDaysRemaining() public view returns (uint256) {
        require(stakerByAddress[msg.sender].value > 0, "No staker");
        uint256 secondsPassed =  block.timestamp - stakerByAddress[msg.sender].stakeStartedDate;
        return secondsPassed >= 200 * secondsInOneDay ? 0 : 200 - secondsPassed / secondsInOneDay;
    }

     /**
     * @dev lets user claim the reward and get back his tokens
     * this function fail if the staking period is not over
     */
    function claimReward() public afterStakePeriod {
        uint256 stakingValue = stakerByAddress[msg.sender].value;
        // to prevent reentrancy attack we set value to zero before send tokens to user
        stakerByAddress[msg.sender].value = 0;
        stakerByAddress[msg.sender].stakeStartedDate = 0;
        _mint(msg.sender, stakingValue * 3);
    }
}