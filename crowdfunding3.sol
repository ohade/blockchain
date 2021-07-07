// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;



contract CrowdfundingProject {
    // Data structures
    enum State {
        Fundraising,
        Expired,
        Successful,
        SuccessfulAndWithdrawn
    }

    // State variables
    address[3] owners; // project owners
    uint public amountGoal; // required to reach at least this much, else everyone gets refund
    uint public completeAt;
    uint256 public currentBalance;
    uint public raiseBy;
    string public title;
    State public state = State.Fundraising; // initialize on create
    mapping (address => uint) public contributions;

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, uint amount, uint currentTotal);
    // Event that will be emitted whenever funding can't be received anymore
    event FundingRejected(address contributor, uint amount, uint currentTotal);
    // Event that will be emitted whenever the project ended successfully and money withdrawn
    event fundsWithdrawn(address recipient);

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    modifier inStateExpiredCampaign() {
        updateIfFundingCompleteOrExpired();
        require(state == State.Expired);
        _;
    }
    // Modifier to check if the function caller is the project creator
//    modifier isCreator() {
//        require(msg.sender == creator);
//        _;
//    }

    constructor
    (
        address[3] memory projectOwners,
        uint durationInSeconds,
        uint goalAmount
    ) public {
        require(noDuplicateEntries(projectOwners), "need to have 3 distinct owners");
        require(durationInSeconds > 0, "duration needs to be positive");
        require(goalAmount > 0, "amountToRaise needs to be positive");

        owners = projectOwners;
        raiseBy = block.timestamp + (durationInSeconds * 1 seconds);
        amountGoal = goalAmount;
        currentBalance = 0;
    }

    /** @dev Function to fund a certain project.
      */
    function contribute() external payable {
//        require(!isOwner(msg.sender));
        if(inStateOfActiveCampaign() == true) {
            contributions[msg.sender] += msg.value;
            currentBalance += msg.value;
            emit FundingReceived(msg.sender, msg.value, currentBalance);
            updateIfFundingCompleteOrExpired();
        }  else {
            emit FundingRejected(msg.sender, msg.value, currentBalance);
        }
    }

    mapping (uint8 => bool) ownerIdx;
    /** @dev Function to give the received funds to project starter.
      */
    function withdrawFunds(bytes32 _msgHash, uint8[2] memory _v, bytes32[2] memory _r, bytes32[2] memory _s) public inState(State.Successful) payable returns (bool) {
        uint8 counter = 0;

        for(uint8 i = 0; i < 2; i++) {
            for(uint8 j = 0; j < owners.length; j++) {
                if (ownerIdx[j] == true) {
                    continue;
                }
                if(isOwnerSignedMsg(owners[j], _msgHash, _v[i], _r[i], _s[i]) == true) {
                    ownerIdx[j] = true;
                    counter += 1;
                    break;
                }
            }
        }

        if(counter == 2) {
            uint256 totalRaised = currentBalance;
            currentBalance = 0;

            if (payable(address(msg.sender)).send(totalRaised)) {
                emit fundsWithdrawn(msg.sender);
                state = State.SuccessfulAndWithdrawn;
                return true;
            } else {
                currentBalance = totalRaised;
                state = State.Successful;
            }
        }
        return false;
    }

    /** @dev Function to retrieve donated amount when a project expires.
      */
    function getRefund() public inStateExpiredCampaign() payable returns (bool) {
        require(contributions[msg.sender] > 0);

        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (payable(msg.sender).send(amountToRefund)) {
            currentBalance -= amountToRefund;
        } else {
            contributions[msg.sender] = amountToRefund;
            return false;
        }
        return true;
    }

    /** @dev Function to change the project state depending on conditions.
      */
    function updateIfFundingCompleteOrExpired() internal {
        if (currentBalance >= amountGoal) {
            state = State.Successful;
        }
        else if (block.timestamp > raiseBy && state != State.SuccessfulAndWithdrawn)  {
            state = State.Expired;
        }
        completeAt = block.timestamp;
    }

     /** @dev Function to get specific information about the project.
      * return Returns all the project's details
      */
    function updateDetails() public {
        updateIfFundingCompleteOrExpired();
    }

    /** @dev Function to get specific information about the project.
      * return Returns all the project's details
      */
    function getDetails() public view returns
    (
        uint256 deadline,
        State currentState,
        uint256 currentAmount,
        uint256 goalAmount
    ) {
        deadline = raiseBy;
        currentState = state;
        currentAmount = currentBalance;
        goalAmount = amountGoal;
    }

    // validate the owner, by validating his signature vs the signed msg.
    function isOwnerSignedMsg(address owner, bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        return ecrecover(msgHash,v,r,s) == owner;
    }

    function isOwner(address _address) internal view returns (bool) {
        for(uint8 i = 0; i < owners.length; i++) {
            if(owners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    mapping (address => bool) exists;
    function noDuplicateEntries(address[3] memory entries) internal returns(bool) {

        for(uint8 i = 0; i < entries.length; i++) {
            if (exists[entries[i]] == false) {
                exists[entries[i]] = true;
            } else {
                return false;
            }
        }
        return true;
    }

    function inStateOfActiveCampaign() internal returns(bool) {
        updateIfFundingCompleteOrExpired();
        return (state == State.Fundraising  || state == State.Successful);
    }
}