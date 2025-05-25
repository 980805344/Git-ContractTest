// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "hardhat/console.sol";

interface IERC20 {
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}

contract CrowdFund {
    // 发起众筹
    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    // 取消
    event Cancel(uint id);
    // 投资
    event Pledge(uint id, address indexed caller, uint amount);
    // 取回投资金额
    event Unpledge(uint id, address indexed caller, uint amount);
    // 宣告结束
    event Claim(uint id);
    // 失败退款
    event Refund(uint id, address indexed caller, uint amount);
    // 众筹
    struct Campaign {
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    IERC20 public token;

    uint public count;
    mapping(uint => Campaign) public campaigns;

    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor (address _token) {
        token = IERC20(_token);
    }

    function launch(uint _goal, uint _startOffset, uint _endOffset) external {
        require(_startOffset < _endOffset, "_startOffset > _endOffset");
        require(_endOffset < 30 days, "_endOffset > 30 days");
        uint32 _startAt = uint32(block.timestamp + _startOffset);
        uint32 _endAt = uint32(block.timestamp + _endOffset);
        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "already started");
        delete campaigns[_id];
        emit Cancel(_id);
    }

    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "failed");

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ended");

        pledgedAmount[_id][msg.sender] -= _amount;
        campaign.pledged -= _amount;

        bool success = token.transfer(msg.sender, _amount);
        require(success, "failed");

        emit Unpledge(_id, msg.sender, _amount);

    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp >= campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledge < goal");

        campaign.claimed = true;
        bool success = token.transfer(msg.sender, campaign.pledged);
        require(success, "failed");
        emit Claim(_id);
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "pledged >= goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        bool success = token.transfer(msg.sender, bal);
        require(success, "failed");
        emit Refund(_id, msg.sender, bal);
    }
}
