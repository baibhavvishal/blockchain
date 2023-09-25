// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingSystem {
    address public owner;
    string public electionName;
    bool public electionActive;
    
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    
    mapping(uint256 => Candidate) public candidates;
    
    mapping(address => bool) public hasVoted;
    
    address[] public voters;
    
    event Voted(address indexed voter, uint256 candidateIndex);
    
    event WinnerAnnounced(string winnerName);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }
    
    constructor(string memory _electionName) {
        owner = msg.sender;
        electionName = _electionName;
        electionActive = true;
    }
    
    function addCandidate(string memory _name) public onlyOwner {
        uint256 candidateIndex = candidatesCount();
        candidates[candidateIndex] = Candidate(_name, 0);
    }
    
    function candidatesCount() public view returns (uint256) {
        uint256 count = 0;
        while (candidates[count].voteCount > 0) {
            count++;
        }
        return count;
    }
    
    event Voted(address indexed voter, uint256 candidateIndex, uint256 voteTimestamp, uint256 voteBlockHeight);

    function vote(uint256 _candidateIndex, address _voterAddress, address _tokenAddress) public {
    require(electionActive, "Election is not active.");
    require(!hasVoted[_voterAddress], "You have already voted.");

    IERC20 token = IERC20(_tokenAddress);

    uint256 tokenBalance = token.balanceOf(_voterAddress);
    require(tokenBalance > 0, "You do not have any tokens to vote.");

    require(token.transferFrom(_voterAddress, address(this), 1), "Vote transfer failed.");

    uint256 voteTimestamp = block.timestamp;
    uint256 voteBlockHeight = block.number;

    candidates[_candidateIndex].voteCount++;

    hasVoted[_voterAddress] = true;

    voters.push(_voterAddress);

    emit Voted(_voterAddress, _candidateIndex, voteTimestamp, voteBlockHeight);
}


    function getElectionResults() public view returns (string[] memory, uint256[] memory) {
        uint256 count = candidatesCount();
        string[] memory candidateNames = new string[](count);
        uint256[] memory voteCounts = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            candidateNames[i] = candidates[i].name;
            voteCounts[i] = candidates[i].voteCount;
        }
        
        return (candidateNames, voteCounts);
    }
    
    function announceWinner() public onlyOwner {
        require(!electionActive, "Election is still active.");
        uint256 count = candidatesCount();
        require(count > 0, "No candidates in the election.");
        
        uint256 winningVoteCount = 0;
        string memory winnerName;
        
        for (uint256 i = 0; i < count; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winnerName = candidates[i].name;
            }
        }
        
        emit WinnerAnnounced(winnerName);
    }
    
    function endElection() public onlyOwner {
        electionActive = false;
    }
}
