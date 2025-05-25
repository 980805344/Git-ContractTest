// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IERC721 {
    function transferFrom(address, address, uint) external;
}

contract EnglishAuction {
    // NFT 信息
    IERC721 public immutable nft;
    uint public immutable nftId;

    // 拍卖信息
    address payable public immutable seller;
    uint32 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;

    // 记录历史最高价
    mapping(address => uint) public bids;

    event Start();
    event Bid(address indexed sender, uint amount);
    // 失败者提取款
    event Withdraw(address indexed sender, uint amount);
    event End(address indexed highestBidder, uint highestBid);

    // 初始化
    constructor (address _nft, uint _nftId, uint _startBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        highestBid = _startBid;
        seller = payable(msg.sender);
    }

    // 发起拍卖
    function start() external {
        require(msg.sender == seller, "not seller");
        require(!started, "started");

        started = true;
        // 目前写死拍卖限时
        endAt = uint32(block.timestamp + 60);
        nft.transferFrom(seller, address(this), nftId);
        emit Start();
    }
    // 竞拍
    function bid()  external payable {
        require(started, "no start");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "not enough");

        if (msg.sender != address(0)) {
            bids[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit Bid(msg.sender, msg.value);
    }

    // 买家提款
    function withdraw() external {
        uint balance = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }

    // 结束
    function end() external {
        require(started, "no start");
        require(!ended, "ended");
        // 必须结束时间到了才可
        require(block.timestamp >= endAt, "not ended");

        ended = true;
        if(highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        }else {
            nft.transferFrom(address(this), seller, nftId);
        }
        emit End(highestBidder, highestBid);
    }
}
