// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

// 选票
contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint voteId;
    }
    // 提案
    struct Proposal {
        bytes32 name;
        uint voteCount;
    }

    // 主席
    address public chairperson;

    // 投票者信息
    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for(uint i; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    // 赋予投票权
    function giveRightToVote(address _voter) external {
        require(msg.sender == chairperson,
        "Only chairperson can give right to vote");

        require(!voters[_voter].voted,
        "The voter already voted");

        require(voters[_voter].weight == 0,
        "Voter already has the right to vote");

        voters[_voter].weight = 1;
    }

    // 委托投票
    function delegate(address _to) external {
        Voter storage voter = voters[msg.sender];
        require(voter.weight != 0,
        "You have no right to vote");

        require(!voter.voted,
        "You already voted");

        require(_to != msg.sender,
        "Self-delegation is disallowed");

        // 避免出现闭环委托
        while(voters[_to].delegate != address(0)) {
            _to = voters[_to].delegate;
            require(_to != msg.sender,
            "Found loop in delegation");
        }
        // 直接定位到最后的决策者
        Voter storage delegate = voters[_to];
        require(delegate.weight >= 1);

        voter.voted = true;
        voter.delegate = _to;
        if(delegate.voted) {
            proposals[delegate.voteId].voteCount += voter.weight;
        }else{
            delegate.weight += voter.weight;
        }
    }

    // 投票
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0,
        "Has no right to vote");

        require(!sender.voted, "Already voted");

        sender.voted = true;
        sender.voteId = proposal;

        proposals[proposal].voteCount += sender.weight;
    }
    // 胜出提案
    function winnerProposals() public view returns (uint winnerProposal, bytes32 memory name){
        uint winnerVoteCount = 0;
        for(uint i; i<proposals.length; i++) {
            if(proposals[i].voteCount > winnerVoteCount) {
                winnerVoteCount = proposals[i].voteCount;
                winnerProposal = i;
                name = proposals[i].name;
            }
        }
    }
}