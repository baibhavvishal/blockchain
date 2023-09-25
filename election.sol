// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC20 interface for the custom token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingSystem {
    address public owner;
    string public electionName;
    bool public electionActive;
    
    // Define the structure for a candidate
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    
    // Mapping to store candidates by their index
    mapping(uint256 => Candidate) public candidates;
    
    // Mapping to track whether an address has voted
    mapping(address => bool) public hasVoted;
    
    // Array to store voter addresses
    address[] public voters;
    
    // Event to log the vote
    event Voted(address indexed voter, uint256 candidateIndex);
    
    // Event to announce the winner
    event WinnerAnnounced(string winnerName);
    
    // Modifier to ensure only the owner can perform certain actions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }
    
    // Constructor to initialize the contract
    constructor(string memory _electionName) {
        owner = msg.sender;
        electionName = _electionName;
        electionActive = true;
    }
    
    // Function to add a candidate to the election
    function addCandidate(string memory _name) public onlyOwner {
        uint256 candidateIndex = candidatesCount();
        candidates[candidateIndex] = Candidate(_name, 0);
    }
    
    // Function to get the total number of candidates
    function candidatesCount() public view returns (uint256) {
        uint256 count = 0;
        while (candidates[count].voteCount > 0) {
            count++;
        }
        return count;
    }
    
   // Event to log the vote with timestamp and block height
    event Voted(address indexed voter, uint256 candidateIndex, uint256 voteTimestamp, uint256 voteBlockHeight);

// Function to allow users to vote for a candidate
    function vote(uint256 _candidateIndex, address _voterAddress, address _tokenAddress) public {
    require(electionActive, "Election is not active.");
    require(!hasVoted[_voterAddress], "You have already voted.");

    // Create an instance of the ERC20 token interface
    IERC20 token = IERC20(_tokenAddress);

    // Check the voter's token balance
    uint256 tokenBalance = token.balanceOf(_voterAddress);
    require(tokenBalance > 0, "You do not have any tokens to vote.");

    // Ensure the voter has enough tokens to vote
    require(token.transferFrom(_voterAddress, address(this), 1), "Vote transfer failed.");

    // Record timestamp and block height
    uint256 voteTimestamp = block.timestamp;
    uint256 voteBlockHeight = block.number;

    // Update vote count for the candidate
    candidates[_candidateIndex].voteCount++;

    // Mark the voter as voted
    hasVoted[_voterAddress] = true;

    // Add the voter to the list
    voters.push(_voterAddress);

    // Emit the vote event with timestamp and block height
    emit Voted(_voterAddress, _candidateIndex, voteTimestamp, voteBlockHeight);
}



    
    // Function to view the election results
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
    
    // Function to determine and announce the winner
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
        
        // Emit the winner announcement event
        emit WinnerAnnounced(winnerName);
    }
    
    // Function to end the election
    function endElection() public onlyOwner {
        electionActive = false;
    }
}
