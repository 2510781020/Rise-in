// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    // =========================================
    // 1. STATE VARIABLES
    // =========================================

    address public owner;
    uint256 private counter;

    mapping(uint256 => Proposal) private proposal_history;
    address[] private voted_addresses;

    // =========================================
    // 2. DATA STRUCTURES
    // =========================================

    struct Proposal {
        string title;
        string description;
        uint256 approve;
        uint256 reject;
        uint256 pass;
        uint256 total_vote_to_end;
        bool current_state;
        bool is_active;
    }

    // =========================================
    // 3. CONSTRUCTOR
    // =========================================

    constructor() {
        owner = msg.sender;
        voted_addresses.push(msg.sender);
    }

    // =========================================
    // 4. MODIFIERS
    // =========================================

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }

    modifier active() {
        require(
            proposal_history[counter].is_active,
            "The proposal is not active"
        );
        _;
    }

    modifier newVoter(address _address) {
        require(!isVoted(_address), "Address has already voted");
        _;
    }

    // =========================================
    // 5. PROPOSAL MANAGEMENT
    // =========================================

    // Create a new proposal
    function create(
        string calldata _title,
        string calldata _description,
        uint256 _total_vote_to_end
    ) external onlyOwner {
        require(_total_vote_to_end > 0, "Vote limit must be greater than zero");

        counter += 1;

        proposal_history[counter] = Proposal(
            _title,
            _description,
            0,
            0,
            0,
            _total_vote_to_end,
            false,
            true
        );

        // Reset voters for the new proposal
        voted_addresses = [owner];
    }

    // Terminate the current proposal
    function terminateProposal() external onlyOwner active {
        proposal_history[counter].is_active = false;
    }

    // =========================================
    // 6. VOTING FUNCTIONALITY
    // =========================================

    // Vote options:
    // 0 = Pass (abstain)
    // 1 = Approve
    // 2 = Reject

    function vote(uint8 choice) external active newVoter(msg.sender) {
        require(choice <= 2, "Invalid voting choice");

        Proposal storage proposal = proposal_history[counter];

        // Record the voter
        voted_addresses.push(msg.sender);

        // Count the vote
        if (choice == 1) {
            proposal.approve += 1;
        } else if (choice == 2) {
            proposal.reject += 1;
        } else {
            proposal.pass += 1;
        }

        // Update the current result
        proposal.current_state = calculateCurrentState();

        // Calculate the updated total votes
        uint256 total_vote = proposal.approve + proposal.reject + proposal.pass;

        // End the proposal when the limit is reached
        if (total_vote >= proposal.total_vote_to_end) {
            proposal.is_active = false;
        }
    }

    // =========================================
    // 7. VOTING RESULT CALCULATION
    // =========================================

    // Custom voting logic:
    // At least 2 approvals are required.
    // Approvals must exceed rejections.
    // Abstentions do not affect the result.

    function calculateCurrentState() private view returns (bool) {
        Proposal storage proposal = proposal_history[counter];

        return (proposal.approve >= 2 && proposal.approve > proposal.reject);
    }

    // =========================================
    // 8. HELPER FUNCTIONS
    // =========================================

    // Check whether an address has already voted
    function isVoted(address _address) public view returns (bool) {
        for (uint256 i = 0; i < voted_addresses.length; i++) {
            if (voted_addresses[i] == _address) {
                return true;
            }
        }

        return false;
    }

    // =========================================
    // 9. GETTER FUNCTIONS
    // =========================================

    // Return the current proposal
    function getCurrentProposal() external view returns (Proposal memory) {
        return proposal_history[counter];
    }

    // Return a proposal by its ID
    function getProposal(
        uint256 number
    ) external view returns (Proposal memory) {
        require(number > 0 && number <= counter, "Proposal does not exist");

        return proposal_history[number];
    }

    // Return the number of created proposals
    function getProposalCount() external view returns (uint256) {
        return counter;
    }
}
