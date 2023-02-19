// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Lottery {
    struct Ticket {
        uint256 ticketNumber;
        address payable buyerAddress;
        uint256 amountPaid;
    }

    address payable ownerAddress;
    uint256 public totalTickets;
    uint256 public ticketPrice;
    uint256 public lotteryStartTime;
    uint256 public lotteryEndTime;
    uint256 public ticketsSold = 0;
    uint256 public winningTicketNumber;
    Ticket public winner;
    bool public isLotteryClosed;

    mapping(uint256 => Ticket) public tickets;

    event LotteryCreated(
        address indexed _ownerAddress,
        uint256 _totalTickets,
        uint256 _ticketPrice
    );
    event BoughtTicket(address indexed _buyerAddress, uint256 _ticketPrice);
    event PickedWinner(Ticket _winningTicket);
    event FundedWinner(address indexed _winnerAddress, uint256 _amount);
    event EndedLottery(bool _isLotteryClosed);
    event Refunded(uint256 _totalRefunds, Ticket[] _ticketsRefunded);

    constructor(
        uint256 _totalTickets,
        uint256 _ticketPrice,
        uint256 _lotteryEndTime
    ) {
        isLotteryClosed = false;
        ownerAddress = payable(msg.sender);
        totalTickets = _totalTickets;
        ticketPrice = _ticketPrice;
        lotteryStartTime = block.timestamp;
        lotteryEndTime = _lotteryEndTime * 1 minutes;

        emit LotteryCreated(msg.sender, totalTickets, ticketPrice);
    }

    modifier onlyOwner() {
        require(
            msg.sender == ownerAddress,
            "Only an owner can access this function"
        );
        _;
    }

    modifier meetLotteryCondition() {
        require(
            isLotteryClosed == false,
            "Lottery is closed by lottery creator"
        );
        require(
            block.timestamp >= (lotteryStartTime + lotteryEndTime),
            "The lottery pool is still open"
        );
        require(
            totalTickets == ticketsSold,
            "The lottery tickets are not sold out"
        );
        _;
    }

    function buyTicket() external payable {
        require(ticketsSold < totalTickets, "Tickets are sold out");
        require(
            block.timestamp < (lotteryStartTime + lotteryEndTime),
            "Lottery pool has closed"
        );
        require(
            msg.value == ticketPrice,
            "The amount is not equal to the ticket price"
        );

        Ticket storage ticket = tickets[ticketsSold + 1];
        ticket.ticketNumber = ticketsSold + 1;
        ticket.buyerAddress = payable(msg.sender);
        ticket.amountPaid = msg.value;

        emit BoughtTicket(msg.sender, msg.value);

        ticketsSold++;
    }

    function pickWinner() external onlyOwner meetLotteryCondition {
        require(winningTicketNumber == 0, "Winner already exists");

        winningTicketNumber =
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % totalTickets) +
            1; //unsecure method
        winner = tickets[winningTicketNumber];

        emit PickedWinner(winner);
    }

    function fundWinner() external onlyOwner meetLotteryCondition {
        require(winningTicketNumber != 0, "Pick winner before funding");

        emit FundedWinner(winner.buyerAddress, address(this).balance);

        winner.buyerAddress.transfer(address(this).balance);
    }

    function refund() public onlyOwner {
        require(
            address(this).balance != 0,
            "The lottery contract does not sufficient funds"
        );

        uint256 totalRefunds = 0;
        Ticket[] memory ticketsRefunded = new Ticket[](ticketsSold);

        for (uint256 i = 0; i <= (ticketsSold - 1); i++) {
            tickets[i + 1].buyerAddress.transfer(tickets[i + 1].amountPaid);
            totalRefunds++;
            ticketsRefunded[i] = tickets[i + 1];
        }

        emit Refunded(totalRefunds, ticketsRefunded);
    }

    function endLottery() external onlyOwner {
        isLotteryClosed = true;
        emit EndedLottery(isLotteryClosed);
        refund();
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}
