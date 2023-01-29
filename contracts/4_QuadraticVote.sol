// SPDX-License-Identifier: no-license

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
    struct Proposal {
        // If you can limit the length to a certain number of bytes,
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name; // short name (up to 32 bytes)
        uint256 voteCount; // number of accumulated votes
    }

    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        uint256[] votes; // index of the voted proposal
    }

    address public chairperson;

    mapping(bytes32 => Voter) public voters;

    Proposal[] public proposals;

    uint256 private weight;

    /**
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        weight = proposalNames.length * proposalNames.length - 1;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    /**
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param applicants address of applicant
     */
    function giveRightToVote(bytes32[] memory applicants) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );

        // chairperson can give the right to vote to multiple voters at once to reduce gas
        for (uint256 i = 0; i < applicants.length; i++) {
            bytes32 voter = applicants[i];
            require(!voters[voter].voted, "Already voted.");
            require(voters[voter].weight == 0, "The voter already registered.");
            voters[voter].weight = weight;
        }
    }

    /**
     * @dev Computes the weight is under limit.
     * @param votes vote amount for eveny proposals
     * @return isValid bool of the result
     */
    function caculateWeight(uint256[] memory votes) private view returns (bool isValid){
      require(votes.length <= proposals.length);
      uint256 expectedWeight;
      for (uint256 v = 0; v < votes.length; v++) {
          expectedWeight += votes[v] * votes[v];
        }
      require(expectedWeight <= weight);
      isValid = true;
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[v]'.
     * @param votes vote amount array
     */
    function vote(uint256[] memory votes, bytes32 voterId) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        Voter storage sender = voters[voterId];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.votes = votes;

        require(caculateWeight(votes)); 

        for (uint256 v = 0; v < votes.length; v++) {
          proposals[v].voteCount += votes[v];
          sender.weight -= votes[v] * votes[v];
        }
    }

    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    /**
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
