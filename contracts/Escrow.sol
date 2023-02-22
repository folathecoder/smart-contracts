// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Escrow {
    address payable public depositor;
    address payable public beneficiary;
    address payable public arbiter;
    uint256 public escrowStartTime;
    uint256 public escrowEndTime;

    event FundedBeneficiary(address indexed _beneficiary, uint256 _amount);
    event RefundedDepositor(address indexed _depositor, uint256 _amount);
    event FundedEscrow(address indexed _depositor, uint256 _amount);

    constructor(
        address payable _beneficiary,
        address payable _arbiter,
        uint256 _endTimeInMinutes
    ) payable {
        require(msg.sender != _arbiter, "Depositor cannot be the arbiter");
        require(
            msg.sender != _beneficiary,
            "Depositor cannot be the beneficiary"
        );
        require(_beneficiary != _arbiter, "Beneficiary cannot be the arbiter");

        depositor = payable(msg.sender);
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        escrowStartTime = block.timestamp;
        escrowEndTime = _endTimeInMinutes * 1 minutes;

        emit FundedEscrow(msg.sender, msg.value);
    }

    modifier onlyArbiter() {
        require(
            msg.sender == arbiter,
            "Only an arbiter can call this contract"
        );
        _;
    }

    modifier escrowNotExpired() {
        require(
            block.timestamp <= (escrowStartTime + escrowEndTime),
            "The escrow has expired, refund the despositor"
        );
        _;
    }

    function fundBeneficiary() external onlyArbiter escrowNotExpired {
        emit FundedBeneficiary(beneficiary, address(this).balance);
        beneficiary.transfer(address(this).balance);
    }

    function refundDepositor() external onlyArbiter {
        emit RefundedDepositor(beneficiary, address(this).balance);
        depositor.transfer(address(this).balance);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}
