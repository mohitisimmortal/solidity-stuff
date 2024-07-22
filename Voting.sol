// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract vote {
    enum Gender {
        Male,
        Female,
        NotSpecified,
        Other
    }

    struct Voter {
        string name;
        uint256 age;
        uint256 voterId;
        Gender gender;
        uint256 voteCandidateId;
        address voterAddress;
        bool hasVoted;
    }

    struct Candidate {
        string name;
        string party;
        uint256 age;
        Gender gender;
        uint256 candidateId;
        address candidateAddress;
        uint256 votes;
    }

    address public electionCommission;
    address[] public winners; //winners address array for Tie scenario
    uint256 public nextVoterId;
    uint256 public nextCandidateId;
    uint256 public startTime;
    uint256 public endTime;
    bool public stopVoting;

    // constructor --
    constructor() {
        electionCommission = msg.sender;
    }

    // modifiers --
    modifier onlyCommissioner() {
        require(msg.sender == electionCommission, "Not Authorized");
        _;
    }

    modifier ageCheck(uint256 _age) {
        require(_age >= 18, "Age must be greater than 18");
        _;
    }

    modifier isVotingTimeInitialized() {
        require(startTime != 0, "voting time hasn't decided yet");
        _;
    }

    // mappings --
    mapping(uint256 => Voter) public voterDetails;
    mapping(uint256 => Candidate) public candidateDetails;
    mapping(address => bool) public isVoterRegistered;
    mapping(address => bool) public isCandidateRegistered;

    // funnctions --
    // func to set duration of voting period
    function setVotingPeriod(uint256 _startTime, uint256 _endTime) public {
        startTime = block.timestamp + _startTime;
        endTime = startTime + _endTime;
        // ex- if inputs are 0,3600 then voting starts on func call and run till 1hr.
    }

    // func to stop voting
    function emergencyStopVoting() public onlyCommissioner {
        stopVoting = true;
    }

    // func to register voter-
    function registerVoter(
        string calldata _name,
        uint256 _age,
        Gender _gender
    ) public ageCheck(_age){
        // check if voter is already registerd or not-
        require(!isVoterRegistered[msg.sender], "Already registered");

        voterDetails[nextVoterId] = Voter({
            name: _name,
            age: _age,
            voterId: nextVoterId,
            gender: _gender,
            voteCandidateId: 0,
            voterAddress: msg.sender,
            hasVoted: false
        });
        isVoterRegistered[msg.sender] = true;
        nextVoterId++;
    }

    // func to get all voter-
    function getVoterList() public view returns (Voter[] memory) {
        Voter[] memory voterList = new Voter[](nextVoterId);
        for (uint256 i = 0; i < nextVoterId; i++) {
            voterList[i] = voterDetails[i];
        }
        return voterList;
    }

    // func to register candidate-
    function registerCandidate(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        Gender _gender
    ) public ageCheck(_age){
        // check if candidate is already registerd or not-
        require(!isCandidateRegistered[msg.sender], "Already registered");

        candidateDetails[nextCandidateId] = Candidate({
            name: _name,
            party: _party,
            age: _age,
            gender: _gender,
            candidateId: nextCandidateId,
            candidateAddress: msg.sender,
            votes: 0
        });
        isCandidateRegistered[msg.sender] = true;
        nextCandidateId++;
    }

    // func to get all candidates-
    function getCandidateList() public view returns (Candidate[] memory) {
        Candidate[] memory candidateList = new Candidate[](nextCandidateId);
        for (uint256 i = 0; i < nextCandidateId; i++) {
            candidateList[i] = candidateDetails[i];
        }
        return candidateList;
    }

    // func to cast vote-
    function castVote(uint256 _voterId, uint256 _candidateId)
        public
        isVotingTimeInitialized
    {
        //check if voting is started or not -
        require(block.timestamp >= startTime, "Voting hasn't started yet");

        //check if voting time isn't over -
        require(
            !stopVoting && block.timestamp <= endTime,
            "Voting time is over"
        );

        require(
            voterDetails[_voterId].voterAddress == msg.sender,
            "Not Authorized"
        );
        require(!voterDetails[_voterId].hasVoted, "Already Voted");
        require(_candidateId < nextCandidateId, "Candidate not found");
        voterDetails[_voterId].voteCandidateId = _candidateId;
        voterDetails[_voterId].hasVoted = true;
        candidateDetails[_candidateId].votes++;
    }

    // func to announce result of voting
    function announceVotingResult()
        public
        onlyCommissioner
        isVotingTimeInitialized
        returns (address[] memory)
    {
        //check if voting is finished or not -
        require(
            stopVoting || block.timestamp > endTime,
            "voting hasn't finished yet"
        );

        // Clear previous winners -
        delete winners;

        uint256 highestVotes;
        for (uint256 i = 0; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes > highestVotes) {
                highestVotes = candidateDetails[i].votes;
            }
        }
        for (uint256 i = 0; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes == highestVotes) {
                winners.push(candidateDetails[i].candidateAddress);
            }
        }
        return winners;
    }
}
