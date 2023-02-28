// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Voting {
    address public adminAddress;
    string public position;
    bool public canVote;
    uint256 public votingStartTime;
    uint256 public votingDurationTime;
    uint256 public noOfContestants = 0;
    uint256 public noOfVoters = 0;

    struct Contestant {
        string contestantName;
        address contestantAddress;
        uint256 noOfVotes;
        address[] voters;
    }

    struct Voter {
        address voterAddress;
    }

    mapping(uint256 => mapping(address => Contestant)) public contestants;
    mapping(uint256 => Voter) public voters;

    event RegisteredContestant(address indexed _contestantAddress);
    event EnabledVoting(bool _canVote);
    event Voted(
        address indexed _voterAddress,
        address indexed _contestantAddress
    );

    modifier onlyAdmin() {
        require(
            msg.sender == adminAddress,
            "Only admin can call this function"
        );
        _;
    }

    constructor(string memory _position) {
        adminAddress = msg.sender;
        position = _position;
    }

    function _checkIfContestantExist(address _contestantAddress)
        internal
        view
        returns (bool)
    {
        bool contestantExist = false;

        for (uint256 i = 0; i < noOfContestants; i++) {
            if (
                bytes(contestants[i + 1][_contestantAddress].contestantName)
                    .length > 0
            ) {
                contestantExist = true;
            }
        }

        return contestantExist;
    }

    function _checkIfContestantExist(
        uint256 _contestantIndex,
        address _contestantAddress
    ) internal view returns (bool) {
        return
            bytes(
                contestants[_contestantIndex][_contestantAddress].contestantName
            ).length > 0;
    }

    function _checkIfVoted(address _voterAddress) internal view returns (bool) {
        bool voterExist = false;

        for (uint256 i = 0; i < noOfVoters; i++) {
            if (voters[i + 1].voterAddress == _voterAddress) {
                voterExist = true;
            }
        }
        return voterExist;
    }

    function registerContestant(
        string calldata _contestantName,
        address _contestantAddress
    ) external onlyAdmin {
        require(
            _checkIfContestantExist(_contestantAddress) == false,
            "The contestant already exists"
        );

        Contestant storage constentant = contestants[noOfContestants + 1][
            _contestantAddress
        ];
        constentant.contestantName = _contestantName;
        constentant.contestantAddress = _contestantAddress;

        noOfContestants++;

        emit RegisteredContestant(_contestantAddress);
    }

    function enableVoting(uint256 _votingDurationInMinutes) external onlyAdmin {
        canVote = true;
        votingStartTime = block.timestamp;
        votingDurationTime = _votingDurationInMinutes * 1 minutes;

        emit EnabledVoting(canVote);
    }

    function vote(uint256 _indexOfContestant, address _contestantAddress)
        external
    {
        require(canVote == true, "Voting is not enabled");
        require(
            block.timestamp <= (votingStartTime + votingDurationTime),
            "Voting has ended"
        );
        require(
            _checkIfContestantExist(_indexOfContestant, _contestantAddress) ==
                true,
            "The contestant does not exist"
        );
        require(
            _checkIfVoted(msg.sender) == false,
            "This address has already voted"
        );

        Voter storage voter = voters[noOfVoters + 1];
        voter.voterAddress = msg.sender;
        noOfVoters++;

        Contestant storage constentant = contestants[_indexOfContestant][
            _contestantAddress
        ];
        constentant.noOfVotes = constentant.noOfVotes + 1;
        constentant.voters.push(msg.sender);

        emit Voted(msg.sender, constentant.contestantAddress);
    }

    // Coding Challenge
    // Create the following functions

    // (1) getWinner function
    // (2) getAllConstants function
    // (3) getAllVoters function
}
