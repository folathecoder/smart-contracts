// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTMarketPlace is ERC721URIStorage {
    using Counters for Counters.Counter;

    address payable owner;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    uint256 private listPrice = 0.01 ether;

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool listed;
    }

    mapping(uint256 => ListedToken) private listedTokens;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this funtion");
        _;
    }

    constructor() ERC721("NFTMarket", "NFM") {
        owner = payable(msg.sender);
    }

    function updateListingPrice(uint256 _listPrice) external onlyOwner {
        listPrice = _listPrice;
    }

    function getListingPrice() external view returns (uint256) {
        return listPrice;
    }

    function getCurrentListedToken()
        external
        view
        returns (ListedToken memory)
    {
        return listedTokens[_tokenIds.current()];
    }

    function getListedToken(uint256 _tokenId)
        external
        view
        returns (ListedToken memory)
    {
        return listedTokens[_tokenId];
    }

    function getTotalListedTokens() external view returns (uint256) {
        return _tokenIds.current();
    }

    function createToken(string memory _tokenURI, uint256 _price)
        external
        payable
        returns (uint256)
    {
        require(
            msg.value == listPrice,
            "The amount payable must be equal to the list price"
        );
        require(
            _price > 0,
            "The token price should be greater than zero and should not be a negative value"
        );

        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current();

        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, _tokenURI);

        _createListedToken(currentTokenId, _price);

        return currentTokenId;
    }

    function _createListedToken(uint256 _tokenId, uint256 _price) private {
        listedTokens[_tokenId] = ListedToken(
            _tokenId,
            payable(address(this)),
            payable(msg.sender),
            _price,
            false
        );

        _transfer(msg.sender, address(this), _tokenId); // transfer ownership to the contract
    }

    function getAllNFTs() external view returns (ListedToken[] memory) {
        uint256 totalListedTokens = _tokenIds.current();
        ListedToken[] memory allListedTokens = new ListedToken[](
            totalListedTokens
        );

        for (uint256 i = 0; i < totalListedTokens; i++) {
            allListedTokens[i] = listedTokens[i + 1];
        }

        return allListedTokens;
    }

    function getMyNFTs() external view returns (ListedToken[] memory) {
        uint256 totalListedTokens = _tokenIds.current();
        uint256 noOfOwnedNFTs = 0;

        for (uint256 i = 0; i < totalListedTokens; i++) {
            if (
                listedTokens[i + 1].owner == msg.sender ||
                listedTokens[i + 1].seller == msg.sender
            ) {
                noOfOwnedNFTs++;
            }
        }

        ListedToken[] memory allMyListedTokens = new ListedToken[](
            noOfOwnedNFTs
        );

        for (uint256 i = 0; i < totalListedTokens; i++) {
            if (
                listedTokens[i + 1].owner == msg.sender ||
                listedTokens[i + 1].seller == msg.sender
            ) {
                allMyListedTokens[i] = listedTokens[i + 1];
            }
        }

        return allMyListedTokens;
    }

    function executeSale(uint256 _tokenId) external payable {
        require(
            msg.value == listedTokens[_tokenId].price,
            "The amount payable must be equal to the token price"
        );

        ListedToken memory listedToken = listedTokens[_tokenId];

        address payable seller = listedToken.seller;

        listedToken.listed = true;
        listedToken.seller = payable(msg.sender);

        _itemsSold.increment();

        _transfer(address(this), msg.sender, _tokenId);
        approve(address(this), _tokenId);

        owner.transfer(listPrice);
        seller.transfer(msg.value);
    }
}
