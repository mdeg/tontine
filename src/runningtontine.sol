pragma solidity ^0.4.21;

import "./lib.sol";
import "./participant.sol";

contract RunningTontine {

    uint constant ONE_YEAR_IN_SECONDS = 31536000;

    // Controls the current state of the tontine
    enum State {
        // Money is currently with investment target
        INVESTING,
        // Contract has begun paying out
        PAYING_OUT
    }
    // Initially, the tontine is in the investment phase
    State state = State.INVESTING;

    // The address of the initial tontine contract
    address initialTontineAddress;

    // The address of the contract where the money is invested
    address investmentTarget;

    // The timestamp we used on launch
    uint launchTs;

    // The interval until the next payout in seconds
    uint payoutIntervalInSeconds;

    // The period of time participants have to collect their money
    uint payoutPeriod;

    // Mapping of the share of all current participants in the tontine
    // A non-zero value here implies that a participant is still in the tontine
    mapping ( address => uint256 ) participantShare;

    // Iterable list of addresses of all participants
    address[] public participants;

    // Participant count to allow traversal
    uint numParticipants = 0;

    // Addresses that have been verified and their identity tokens
    mapping ( address => bytes32 ) verifiedIdentities;

    constructor(address _investmentTarget) public {
        launchTs = now;
        investmentTarget = _investmentTarget;

        payoutIntervalInSeconds = launchTs + ONE_YEAR_IN_SECONDS;

        // Seed the investment target with our initial investment
        investmentTarget.transfer(address(this).balance);
    }

    // TODO: work out how to timer this
    function endPayoutPeriod() public {
        require(state == State.PAYING_OUT);

        // TODO: expire participants who have not collected

        // Return any uncollected dividends to the investment pool
        investmentTarget.transfer(address(this).balance);

        state = State.INVESTING;
    }

    // Receive dividends from the investment contract
    function receiveReturnOnInvestment() external payable {
        require(msg.sender == investmentTarget);
        state = State.PAYING_OUT;

        uint expiry = now + payoutPeriod;

        // Notify all surviving participants that their funds are ready to collect
        for (uint i = 0; i < numParticipants; i++) {
            if (participantShare[participants[i]] != 0) {
                Participant(participants[i]).notify(expiry);
            }
        }
    }

    // Add a new participant to the running tontine
    function addParticipant(address participant, uint256 share) external {
        require(msg.sender == initialTontineAddress);

        participantShare[participant] = share;
        participants.push(participant);
        numParticipants++;
    }

    // Called by a participant attempting to retrieve funds from this running tontine
    function retrieve(bytes32 identityToken) external payable {
        require(state == State.PAYING_OUT);
        require(participantShare[msg.sender] > 0);

        // Verify that we have an identity token and it matches
        require(identityToken == verifiedIdentities[msg.sender]);

        // Return the users' calculated dividend
        msg.sender.transfer(address(this).balance / participantShare[msg.sender]);
    }

    // Remove a participant from the tontine and devolve their share to surviving participants
    function devolve(address participant) internal {

        emit Devolve(participant);

        uint256 share = participantShare[participant];

        participantShare[participant] = 0;
        // TODO: remove a participant and divide their shares between remaining participants
        // TODO: if there is only one participant left, wrap up this contract
    }

    // The running tontine has devolved to the final participant
    // Wrap up the tontine and return all our funds to the originator
    function wrapUp(address _survivor) internal {
        emit WrapUp(_survivor, now);

        // TODO: kill investment target
        // TODO: ensure investment has returned all funds
        selfdestruct(_survivor);
    }

    event Devolve(address);
    event WrapUp(address survivor, uint ts);
}