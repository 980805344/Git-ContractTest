pragma version ^0.8.7;

contract MultiSigWallet {
    // 质押事件
    event Deposit(address indexed sender, uint amount);
    // 提交交易事件
    event Submit(uint txId);
    // 授权事件
    event Approve(address indexed sender, uint txId);
    // 撤销事件
    event Revoke(address indexed sender, uint txId);
    // 执行交易事件
    event Execute(uint txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approve;

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owner required");
        require(_required <= _owners.length, "invalid required");
        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid address");
            require(!isOwner[owner], "duplicate owners");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    modifier onlyOwner {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier isExist(uint txId) {
        require(txId <= transactions.length, "invalid txId");
        _;
    }

    modifier notApproved(uint txId) {
        require(!approve[txId][msg.sender], "already approved");
        _;
    }

    modifier notExecuted(uint txId) {
        require(!transactions[txId].executed, "already executed");
        _;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes memory _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) external onlyOwner isExists(_txId) notApproved(_txId) {
        approve[txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) internal view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if(approve([_txId][owners[i]])) {
                count += 1;
            }
        }
    }

    function execute(uint _txId) external onlyOwner isExists(_txId) notExecute(_txId) {

        require(_getApprovalCount(_txId) >= required, "not enough approval");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = payable(transaction.to).call{value: transaction.value}(transaction.data);
        require(success, "failed");
        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner isExists(_txId) notExecute(_txId) {
        require(approve[_txId][msg.sender], "not approved");
        approve[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}