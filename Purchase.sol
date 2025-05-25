// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract Purchase {
    // 物品价值
    uint public value;
    // 卖家
    address payable public seller;
    // 买家
    address payable public buyer;
    // 状态
    enum State {
        Created,
        Locked,
        Release,
        Inactive
    }

    State public status;

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    error OnlyBuyer();
    error OnlySeller();
    error InvalidState();
    // 提供的值必须是偶数
    error ValueNotEven();

    modifier onlyBuyer() {
        if(msg.sender != buyer) {
            revert OnlyBuyer();
        }
        _;
    }
    modifier onlySeller() {
        if(msg.sender != seller) {
            revert OnlySeller();
        }
        _;
    }
    modifier inState(State _status) {
        if(status != _status) {
            revert InvalidState();
        }
        _;
    }
    // 中止
    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        if((value *2) != msg.value) {
            revert ValueNotEven();
        }
    }

    // 中止
    function abort() external onlySeller inState(State.Created) {
        emit Aborted();
        status = State.Inactive;
        seller.transfer(address(this).balance);
    }

    // 确认购买
    function confirmPurchase() 
    external payable 
    onlyBuyer 
    inState(State.Created) 
    condition(msg.value == (2 * value)) {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        status = State.Locked;
    }

    // 确认收到
    function confirmReceived() external onlyBuyer inState(State.Locked) {
        emit ItemReceived();
        status = State.Release;

        buyer.transfer(value);
        seller.transfer(3 * value);
    }
    // 卖方退款
    function refundSeller() external onlySeller inState(State.Release) {
        emit SellerRefunded();
        status = State.Inactive;

        buyer.transfer(2 * value);
    }
}