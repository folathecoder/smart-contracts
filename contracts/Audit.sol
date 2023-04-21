// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @audit - This is an audit
// @audit-info - This is an audit info
// @audit-issue - This is an issue


enum CampaignState {
    Active,
    Completed,
    Ended,
    Protested,
    Paused,
    Blocked
}

enum StateChanger {
    Ok,
    Admin,
    Creator,
    Donors
}

contract Charity {
    address payable private adminAddress;
    uint256 public campaignCount = 0;

    struct Donor {
        address payable donorAddress;
        uint256 donatedAmount;
    }

    struct Campaign {
        uint256 campaignId;
        address payable campaignAddress;
        uint256 campaignTarget;
        uint256 amountDonated;
        Donor[] donors;
        CampaignState campaignState;
        StateChanger pausedBy;
        StateChanger blockedBy;
    }

    mapping(uint256 => Campaign) public campaigns;
    
    event CreatedCampaign(uint256 indexed campaignId, address campaignAddress, uint256 campaignTarget);
    event PausedCampaign(uint256 indexed campaignId, address campaignAddress, StateChanger pausedBy);
    event BlockCampaign(uint256 indexed campaignId, address campaignAddress, StateChanger blockedBy);
    event Donated(uint256 indexed campaignId, address campaignAddress, Donor donor);
    event Refunded(address indexed donorAddress, uint256 donatedAmount);

    string constant ERROR_CAMPAIGN_NOT_FOUND = "Campaign does not exist: Check the campaign id, campaign address, or both";
    string constant ERROR_ONLY_CREATOR = "Only campaign creator can pause the campaign using this function";
    string constant ERROR_ONLY_CREATOR_ADMIN = "Only campaign creator or admin can pause the campaign using this function";
    string constant ERROR_ONLY_ADMIN = "Only admin can perform this action";
    string constant ERROR_ADMIN_CANNOT = "Admin cannot perform this action";
    string constant ERROR_INSUFFICIENT_AMOUNT = "Amount sent is not sufficient: Send more than zero ETH";
    string constant ERROR_CAMPAIGN_BLOCKED = "Campaign already blocked";
    string constant ERROR_CAMPAIGN_PAUSED = "Campaign already paused";

    constructor() {
        adminAddress = payable(msg.sender);
    }

    modifier onlyAdmin {
        require(msg.sender == adminAddress, ERROR_ONLY_ADMIN);
        _;
    }

    function createCampaign(uint256 _campaignTarget) external {
        require(msg.sender != adminAddress, ERROR_ADMIN_CANNOT);

        uint256 campaignId = campaignCount++;
        Campaign storage campaign = campaigns[campaignId];

        campaign.campaignId = campaignId;
        campaign.campaignAddress = payable(msg.sender);
        campaign.campaignTarget = _campaignTarget;
        campaign.campaignState = CampaignState.Active;
        campaign.pausedBy = StateChanger.Ok;
        campaign.blockedBy = StateChanger.Ok;

        emit CreatedCampaign(campaignId, msg.sender, _campaignTarget);
    }

    function _campaignExist(uint256 _campaignId, address _campaignAddress) internal view returns(bool) {
        bool checkCampaignId = _campaignId <= campaignCount && _campaignId >= 0;
        bool checkCampaignAddress = campaigns[_campaignId].campaignAddress == _campaignAddress;

        if (checkCampaignId && checkCampaignAddress) {
            return true;
        } else {
            return false;
        }
    }

    function pauseCampaign(uint256 _campaignId, address _campaignAddress) external {
        require(_campaignExist(_campaignId, _campaignAddress), ERROR_CAMPAIGN_NOT_FOUND); 
        require(campaigns[_campaignId].campaignAddress == msg.sender, ERROR_ONLY_CREATOR);
        require(campaigns[_campaignId].campaignState != CampaignState.Paused, ERROR_CAMPAIGN_PAUSED);

        campaigns[_campaignId].campaignState = CampaignState.Paused;
        campaigns[_campaignId].pausedBy = StateChanger.Creator;

        emit PausedCampaign(_campaignId, _campaignAddress, StateChanger.Creator);
    }
       
    function blockCampaign(uint256 _campaignId, address _campaignAddress) external {
        require(_campaignExist(_campaignId, _campaignAddress), ERROR_CAMPAIGN_NOT_FOUND); 

        bool isCampaignCreator = campaigns[_campaignId].campaignAddress == msg.sender;
        bool isAdmin = msg.sender == adminAddress;

        require(isCampaignCreator || isAdmin, ERROR_ONLY_CREATOR_ADMIN);
        require(campaigns[_campaignId].campaignState != CampaignState.Blocked, ERROR_CAMPAIGN_BLOCKED);

        campaigns[_campaignId].campaignState = CampaignState.Blocked;

        if (isCampaignCreator) {
            campaigns[_campaignId].blockedBy = StateChanger.Creator;
            emit BlockCampaign(_campaignId, _campaignAddress, StateChanger.Creator);
        } else if (isAdmin) {
            campaigns[_campaignId].blockedBy = StateChanger.Admin;
            emit BlockCampaign(_campaignId, _campaignAddress, StateChanger.Admin);
        }


        _refund(_campaignId, _campaignAddress);
    }

    function donate(uint256 _campaignId, address _campaignAddress) external payable {
        require(_campaignExist(_campaignId, _campaignAddress), ERROR_CAMPAIGN_NOT_FOUND);
        require(campaigns[_campaignId].campaignState != CampaignState.Paused, "Campaign already paused");
        require(campaigns[_campaignId].campaignState != CampaignState.Blocked, "This campaign has been blocked, donation is deactivated");
        require(campaigns[_campaignId].campaignState != CampaignState.Protested, "This campaign is been protested, donation is deactivated");
        require(campaigns[_campaignId].campaignState != CampaignState.Ended, "This campaign has ended, donation is deactivated");
        require(campaigns[_campaignId].campaignState == CampaignState.Active, "This campaign is not active, donation is deactivated");

        require(msg.value > 0, ERROR_INSUFFICIENT_AMOUNT);

        Donor memory donor = Donor(
            payable(msg.sender),
            msg.value
        );

        campaigns[_campaignId].amountDonated = campaigns[_campaignId].amountDonated + msg.value;
        campaigns[_campaignId].donors.push(donor);

        emit Donated(_campaignId, _campaignAddress, donor);
    }

    function _refund(uint256 _campaignId, address _campaignAddress) internal {
        require(_campaignExist(_campaignId, _campaignAddress), ERROR_CAMPAIGN_NOT_FOUND); 

        for (uint256 i = 0; i < campaigns[_campaignId].donors.length; i++) {
            address payable donorAddress = campaigns[_campaignId].donors[i].donorAddress;
            uint256 donatedAmount = campaigns[_campaignId].donors[i].donatedAmount;

            require(donorAddress != address(0), "Invalid receiver address");

            emit Refunded(donorAddress, donatedAmount);
            donorAddress.transfer(donatedAmount);
        }

        campaigns[_campaignId].amountDonated = 0;
    }

    // voting feature
    // withdrawal feature
}