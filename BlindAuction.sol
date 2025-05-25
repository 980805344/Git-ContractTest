// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract BlindAuction {
    // 抽象盲拍出价
    struct Bid {
        // 加密投标
        bytes32 blindBid;
        // 质押
        uint deposit;
    }

    address payable public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    // 加密投票映射
    mapping (address=>Bid[]) public bids;
    // 最高出价人
    address public highestBidder;
    uint public highestBid;

    // 出价历史
    mapping (address=>uint) public pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    error TooEarly(uint time);
    error TooLate(uint time);
    error AuctionEndAlreadyCalled();

    modifier onlyBefore(uint time) {
        if(block.timestamp >= time) 
            revert TooEarly(time);
        _;
    }

    modifier onlyAfter(uint time) {
        if(block.timestamp <= time)
            revert TooLate(time);
        _;
    }

    constructor(uint biddingTimeOffset, uint revealTimeOffset, address payable beneficiaryAddress) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTimeOffset;
        revealEnd = block.timestamp + revealTimeOffset;
    }

    function bid(bytes32 _blindBid) external payable onlyBefore(biddingEnd){
        bids[msg.sender].push(Bid({
            blindBid: _blindBid,
            deposit: msg.value
        }));
    }

    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    ) 
    external
    onlyAfter(biddingEnd)
    onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        require(length == values.length);
        require(length == fakes.length);
        require(length == secrets.length);
        // 退款
        uint refund;
        for (uint i; i<length; i++) {
            // 获取调用者的对应的每条出价信息
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) = 
                (values[i], fakes[i], secrets[i]);
            if(bidToCheck.blindBid != keccak256(abi.encodePacked(value, fake, secret))){
                continue;
            }
            // 累计质押的退款
            refund += bidToCheck.deposit;
            // 真 && 质押金额大于等于出价
            if (!fake && bidToCheck.deposit >= value) {
                // 是最高价
                if(placeBid(msg.sender, value)){
                    refund -= value;
                }
            }
            // 私密报价归0
            bidToCheck.blindBid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
    }

    function winthdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function auctionEnd() external onlyAfter(revealEnd) {
        if (ended) revert AuctionEndAlreadyCalled();
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }

    function placeBid(address bidder, uint value) internal returns (bool) {
        if(value > highestBid) {
            pendingReturns[highestBidder] += highestBid;
            highestBidder = bidder;
            highestBid = value;
            return true;
        }
        return false;
    }
}