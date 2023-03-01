// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CrowdFunder {
    address payable public owner;

    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 targetAmount;
        uint256 amountDonated;
        address[] donors;
        uint256[] donations;
        bool endCampaign;
    }

    uint256 public numberOfCampaigns = 0;

    mapping(uint256 => Campaign) public campaigns;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function createCampaigns(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _targetAmount
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.targetAmount = _targetAmount;
        campaign.amountDonated = 0;
        campaign.endCampaign = false;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaigns(uint256 _campaignId) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_campaignId];
        uint256 donatableAmount = campaign.targetAmount -
            campaign.amountDonated;

        require(amount != 0, "Your donation should be greater than 0");
        require(
            amount <= donatableAmount,
            "Your donation exceeds the requested donation target"
        );

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountDonated = campaign.amountDonated + amount;
            campaign.donors.push(msg.sender);
            campaign.donations.push(amount);
        }
    }

    function getDonors(uint256 _campaignId)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (
            campaigns[_campaignId].donors,
            campaigns[_campaignId].donations
        );
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];
            allCampaigns[i] = campaign;
        }

        return allCampaigns;
    }

    function deleteCampaigns(uint256 _campaignId) public {
        require(
            campaigns[_campaignId].owner == msg.sender,
            "Only the campaign owner can delete a campaign"
        );
        delete campaigns[_campaignId];
    }
}
