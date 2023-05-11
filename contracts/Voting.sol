pragma solidity ^0.8.9;

contract Voting {
    struct Proposal {
        string description;
        uint votes;
    }

    struct Poll {
        string title;
        string description;
        uint startTime;
        uint endTime;
        bool started;
        bool ended;
        Proposal[] proposals;
        Proposal winner;
        mapping(address => uint) weights;
        mapping(address => bool) hasVoted;
    }

    Poll[] public polls;

    function createPoll(string memory _title, string memory _description, uint _startTime, uint _endTime, string memory _proposalDescription) public {
        Poll storage newPoll = polls.push();

        newPoll.title = _title;
        newPoll.description = _description;
        newPoll.startTime = _startTime;
        newPoll.endTime = _endTime;
        newPoll.started = false;
        newPoll.ended = false;
        newPoll.weights[msg.sender] = 2;
        addProposal(polls.length - 1, _proposalDescription);
    }

    function addProposal(uint _pollId, string memory description) public {
        checkPolls();
        require(polls.length > _pollId, "Poll does not exist");
        require(!polls[_pollId].started, "Poll has started");

        uint proposalId = polls[_pollId].proposals.length;
        Proposal memory newProposal = Proposal({
            description: description,
            votes: 0
        });
        polls[_pollId].proposals.push(newProposal);

        require(polls[_pollId].proposals.length == proposalId + 1, "Proposal has not added");
    }

    function getProposalLength(uint _pollId) public view returns (uint) {
        require(polls.length > _pollId, "Poll does not exist");
        return polls[_pollId].proposals.length;
    }

    function vote(uint _pollId, uint _proposalId) public {
        require(polls.length > _pollId, "Poll does not exist");
        require(polls[_pollId].proposals.length > _proposalId, "Proposal does not exist");
        checkPolls();
        Poll storage poll = polls[_pollId];

        require(poll.started, "Poll has not started");
        require(!poll.ended, "Poll has ended");
        require(!poll.hasVoted[msg.sender], "You have already voted");

        poll.proposals[_proposalId].votes += poll.weights[msg.sender];
        poll.hasVoted[msg.sender] = true;
    }

    function endPoll(uint _pollId) public {
        Poll storage poll = polls[_pollId];

        require(!poll.ended, "Poll has already ended");
        require(block.timestamp >= poll.endTime, "Poll has not yet ended");

        uint winningProposalId = 0;
        uint winningVotes = 0;

        for (uint i = 0; i < poll.proposals.length; i++) {
            if (poll.proposals[i].votes > winningVotes) {
                winningProposalId = i;
                winningVotes = poll.proposals[i].votes;
            }
        }

        poll.winner = poll.proposals[winningProposalId];
        poll.ended = true;
    }

    function checkPolls() public {
        for (uint i = 0; i < polls.length; i++) {
            if (!polls[i].ended && block.timestamp >= polls[i].endTime) {
                endPoll(i);
            }
            else if (!polls[i].started && block.timestamp >= polls[i].startTime) {
                polls[i].started = true;
            }
        }
    }

    function getResult(uint _pollId) public view returns (string memory) {
        require(polls[_pollId].ended, "Poll has not ended yet");

        return polls[_pollId].winner.description;
    }
}