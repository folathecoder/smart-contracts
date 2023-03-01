// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BuyMeCoffee {
    address payable private _owner;

    uint256 private _memoCount = 0;

    struct Memo {
        uint256 memoId;
        uint256 donationAmount;
        string memoMessage;
        address donator;
    }

    mapping(uint256 => Memo) private _memos;

    event CreatedMemo(
        uint256 indexed memoId,
        uint256 donationAmount,
        string memoMessage,
        address donator
    );

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    constructor() {
        _owner = payable(msg.sender);
    }

    function buyCoffee(string memory _memoMessage) external payable {
        require(msg.value > 0, "The amount payable shoud be greater than 0");

        uint256 memoId = _memoCount + 1;

        _memos[memoId] = Memo(memoId, msg.value, _memoMessage, msg.sender);

        _memoCount++;

        emit CreatedMemo(memoId, msg.value, _memoMessage, msg.sender);
    }

    function withdraw() external onlyOwner {
        require(
            address(this).balance > 0,
            "The contract has insufficient balance"
        );

        _owner.transfer(address(this).balance);
    }

    function getMemoCount() external view returns (uint256) {
        return _memoCount;
    }

    function getMemo(uint256 _memoId) external view returns (Memo memory) {
        require(_memoId <= _memoCount + 1, "The memoId is invalid");
        return _memos[_memoId];
    }

    function getAllMemos() external view returns (Memo[] memory) {
        Memo[] memory allMemos = new Memo[](_memoCount);

        for (uint256 i = 0; i < _memoCount; i++) {
            allMemos[i] = _memos[i + 1];
        }

        return allMemos;
    }

    function getBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}
