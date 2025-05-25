// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IERC721 {
    function transferFrom(address, address, uint) external;
}

contract DutchAution {
    // NFT 信息
    IERC721 public nft;
    uint public nftId;

    // 拍卖信息
    uint private constant DURATION = 7 days;
    address payable public immutable seller;
    uint public immutable startPrice;
    uint public immutable startAt;
    uint public immutable expiredAt;
    uint public immutable discountRate;

    uint public finalPrice;
    bool public finished;

    // 初始化
    constructor (uint _startPrice, uint _discountRate, address _nft, uint _nftId) {
        require(_startPrice > _discountRate * DURATION, "startPrice < discount Rate");
        require( _nft != address(0), "invalid nft");

        seller = payable(msg.sender);
        startAt = block.timestamp;
        expiredAt = startAt + DURATION;
        startPrice = _startPrice;
        discountRate = _discountRate;

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function buy() external payable {
        require(block.timestamp > startAt, "not start");
        require(block.timestamp < expiredAt, "ended");
        uint price = getPrice();
        require(msg.value >= price, "value < price");
        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        finalPrice = price;
        finished = true;
    }

    function getPrice() internal view returns (uint) {
        uint deltaTime = block.timestamp - startAt;
        return startPrice - deltaTime * discountRate;

    }

    function getMoney() external {
        require(msg.sender == seller, "not seller");
        require(finished, "no finish");

        seller.transfer(finalPrice);

    }
}