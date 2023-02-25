// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PiggyBank {
    address payable public ownerAddress;
    uint256 public lockStartTime;
    uint256 public lockEndTime;

    event CreatedPiggyBank(
        address _ownerAddress,
        uint256 _initialDeposit,
        uint256 _lockStartTime,
        uint256 _lockEndTime
    );
    event Deposited(address _depositorAddress, uint256 _depositAmount);
    event Withdrew(address _withdrawalAddress, uint256 _withdrawalAmount);
    event SetNewLockTime(uint256 _lockStartTime, uint256 _lockEndTime);
    event ExtendedLockTime(uint256 _lockStartTime, uint256 _lockEndTime);

    modifier checkDespositValue() {
        require(msg.value != 0, "The deposit should be above 0");
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == ownerAddress,
            "Only the owner can access this function"
        );
        _;
    }

    constructor(uint256 _lockDurationInMinutes) payable checkDespositValue {
        require(_lockDurationInMinutes != 0, "The lock time must be above 0");

        ownerAddress = payable(msg.sender);
        lockStartTime = block.timestamp;
        lockEndTime = _lockDurationInMinutes * 1 minutes;

        emit CreatedPiggyBank(
            msg.sender,
            msg.value,
            lockStartTime,
            lockStartTime + lockEndTime
        );
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() external payable checkDespositValue {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 _withdrawAmount) external onlyOwner {
        require(
            _withdrawAmount <= balance(),
            "The withdrawal amount should be less than or equal to the contract balance"
        );
        require(
            block.timestamp >= (lockStartTime + lockEndTime),
            "The lock time has not expired"
        );
        require(
            _withdrawAmount > 0,
            "Withdrawal amount should be greater than zero"
        );

        ownerAddress.transfer(_withdrawAmount);

        emit Withdrew(msg.sender, _withdrawAmount);
    }

    function setLockTime(uint256 _lockDurationInMinutes) external onlyOwner {
        require(balance() > 0, "You cannot set lock time for 0 balance");

        uint256 newLockTime = _lockDurationInMinutes * 1 minutes;

        if (block.timestamp >= (lockStartTime + lockEndTime)) {
            lockStartTime = block.timestamp;
            lockEndTime = newLockTime;

            emit SetNewLockTime(lockStartTime, lockEndTime);
        } else {
            require(
                newLockTime > lockEndTime,
                "New lock time should be greater than the current lock time"
            );
            lockEndTime = newLockTime;

            emit ExtendedLockTime(lockStartTime, lockEndTime);
        }
    }
}
