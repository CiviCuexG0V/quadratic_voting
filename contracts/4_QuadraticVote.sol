// SPDX-License-Identifier: no-license

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title QuadraticVote
 * @dev Implements voting process along with vote delegation
 */
contract QVote {
    struct Proposal {
        // If you can limit the length to a certain number of bytes,
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name; // short name (up to 32 bytes)
        uint256 voteCount; // number of accumulated votes
    }

    struct Voter {
        bool voted; // if true, that person already voted
        uint256[] votes; // index of the voted proposal
    }

    address public chairperson;

    mapping(uint256 => Voter) public voters;

    Proposal[] public proposals;

    uint256 private credits;

    /**
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        credits = proposalNames.length * proposalNames.length - 1;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    // modifier to check if credits are correcttly used
    modifier checkCredits(uint256[] memory votes) {
        require(votes.length == proposals.length);
        uint256 _credits_used = 0;
        for (uint256 v = 0; v < votes.length; v++) {
            _credits_used += votes[v] * votes[v];
        }
        require(_credits_used <= credits);
		_;
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[v]'.
     * @param votes vote amount array
     */
    function vote(uint256[] memory votes, uint256 voterId) public checkCredits(votes) {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        Voter storage sender = voters[voterId];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.votes = votes;

        for (uint256 i = 0; i < votes.length; i++) {
            proposals[i].voteCount += votes[i];
        }
    }

    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return _winningProposal index of winning proposal in the proposals array
     */
    function winningProposal() public view returns (uint256 _winningProposal) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                _winningProposal = p;
            }
        }
        return _winningProposal;
    }

    /**
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return _winnerName the name of the winner
     */
    function winnerName() public view returns (bytes32 _winnerName) {
        _winnerName = proposals[winningProposal()].name;
        return _winnerName;
    }
}
Select a repo
