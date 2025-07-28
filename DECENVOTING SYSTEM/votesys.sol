// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DecentralizedVoting
 * @dev A decentralized voting system that allows transparent and secure elections
 * @author Your Name
 */
contract DecentralizedVoting {
    address public owner;
    uint256 public votingEndTime;
    bool public votingActive;
    
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        bool exists;
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedCandidateId;
    }
    
    mapping(uint256 => Candidate) public candidates;
    mapping(address => Voter) public voters;
    uint256 public candidateCount;
    uint256 public totalVotes;
    
    event VoterRegistered(address voter);
    event CandidateAdded(uint256 candidateId, string name);
    event VoteCasted(address voter, uint256 candidateId);
    event VotingStarted(uint256 endTime);
    event VotingEnded();
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "Voter not registered");
        _;
    }
    
    modifier votingIsActive() {
        require(votingActive && block.timestamp < votingEndTime, "Voting is not active");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        votingActive = false;
        candidateCount = 0;
        totalVotes = 0;
    }
    
    // Function 1: Register a new voter
    /**
     * @dev Register a new voter (only owner can call this)
     * @param _voter The address of the voter to register
     */
    function registerVoter(address _voter) external onlyOwner {
        require(!voters[_voter].isRegistered, "Voter already registered");
        require(!votingActive, "Cannot register voters during active voting");
        
        voters[_voter].isRegistered = true;
        voters[_voter].hasVoted = false;
        voters[_voter].votedCandidateId = 0;
        
        emit VoterRegistered(_voter);
    }
    
    // Function 2: Add a new candidate
    /**
     * @dev Add a new candidate to the election (only owner can call this)
     * @param _name The name of the candidate
     */
    function addCandidate(string memory _name) external onlyOwner {
        require(!votingActive, "Cannot add candidates during active voting");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        
        candidateCount++;
        candidates[candidateCount] = Candidate({
            id: candidateCount,
            name: _name,
            voteCount: 0,
            exists: true
        });
        
        emit CandidateAdded(candidateCount, _name);
    }
    
    // Function 3: Start the voting process
    /**
     * @dev Start the voting process with a specified duration
     * @param _durationInMinutes The duration of voting in minutes
     */
    function startVoting(uint256 _durationInMinutes) external onlyOwner {
        require(!votingActive, "Voting is already active");
        require(candidateCount >= 2, "At least 2 candidates required");
        require(_durationInMinutes > 0, "Duration must be greater than 0");
        
        votingEndTime = block.timestamp + (_durationInMinutes * 1 minutes);
        votingActive = true;
        
        emit VotingStarted(votingEndTime);
    }
    
    // Function 4: Cast a vote
    /**
     * @dev Cast a vote for a candidate (only registered voters can call this)
     * @param _candidateId The ID of the candidate to vote for
     */
    function vote(uint256 _candidateId) external onlyRegisteredVoter votingIsActive {
        require(!voters[msg.sender].hasVoted, "Voter has already voted");
        require(candidates[_candidateId].exists, "Candidate does not exist");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = _candidateId;
        candidates[_candidateId].voteCount++;
        totalVotes++;
        
        emit VoteCasted(msg.sender, _candidateId);
    }
    
    // Function 5: End voting manually (only owner)
    /**
     * @dev Manually end the voting process (only owner can call this)
     */
    function endVoting() external onlyOwner {
        require(votingActive, "Voting is not active");
        
        votingActive = false;
        emit VotingEnded();
    }
    
    // Function 6: Get candidate details
    /**
     * @dev Get candidate details by ID
     * @param _candidateId The ID of the candidate to retrieve
     * @return id The candidate's ID
     * @return name The candidate's name
     * @return voteCount The number of votes received by the candidate
     */
    function getCandidate(uint256 _candidateId) external view returns (
        uint256 id,
        string memory name,
        uint256 voteCount
    ) {
        require(candidates[_candidateId].exists, "Candidate does not exist");
        
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }
    
    // Function 7: Get voting results (winner)
    /**
     * @dev Get the winner of the election
     * @return winnerId The ID of the winning candidate
     * @return winnerName The name of the winning candidate  
     * @return winnerVoteCount The vote count of the winning candidate
     */
    function getWinner() external view returns (
        uint256 winnerId,
        string memory winnerName,
        uint256 winnerVoteCount
    ) {
        require(!votingActive || block.timestamp >= votingEndTime, "Voting is still active");
        require(candidateCount > 0, "No candidates available");
        
        uint256 maxVotes = 0;
        uint256 winningCandidateId = 0;
        
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }
        
        require(winningCandidateId > 0, "No winner found");
        
        return (
            winningCandidateId,
            candidates[winningCandidateId].name,
            candidates[winningCandidateId].voteCount
        );
    }
    
    // Function 8: Get voting status and statistics
    /**
     * @dev Get comprehensive voting status and statistics
     * @return isActive Whether voting is currently active
     * @return endTime The timestamp when voting ends
     * @return totalCandidates The total number of candidates
     * @return totalVotesCasted The total number of votes cast
     * @return timeRemaining The time remaining in seconds (0 if voting ended)
     */
    function getVotingStatus() external view returns (
        bool isActive,
        uint256 endTime,
        uint256 totalCandidates,
        uint256 totalVotesCasted,
        uint256 timeRemaining
    ) {
        uint256 remaining = 0;
        if (votingActive && block.timestamp < votingEndTime) {
            remaining = votingEndTime - block.timestamp;
        }
        
        return (
            votingActive && block.timestamp < votingEndTime,
            votingEndTime,
            candidateCount,
            totalVotes,
            remaining
        );
    }
}
