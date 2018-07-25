pragma solidity ^0.4.21;

import "./lib.sol";

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

    // The address of the contract where the money is invested
    address investmentTarget;
    // The timestamp we used on launch
    uint launchTs;
    // The interval until the next payout in seconds
    uint payoutIntervalInSeconds;
    // The period of time participants have to collect their money
    uint payoutPeriod;

    // TODO: maintain a list of valid identity tokens

    // List of all the current participants in the tontine
    mapping ( address => TontineStructs.Participant ) participants;

    constructor(address _investmentTarget) public {
        launchTs = now;
        investmentTarget = _investmentTarget;

        // TODO: transfer sum to investment target

        payoutIntervalInSeconds = launchTs + ONE_YEAR_IN_SECONDS;
    }

    // TODO: work out how to time this
    function endPayoutPeriod() {
        require(state == State.PAYING_OUT);

        // TODO: expire participants who have not collected

        // TODO: return expired dividends to investment pool

        state = State.INVESTING;
    }

    // Receive dividends from the investment contract
    function receiveReturnOnInvestment() external payable {
        require(msg.sender == investmentTarget);
        state = State.PAYING_OUT;
        // TODO: notify all participants
    }

    // Retrieve funds
    function retrieve(bytes32 identityToken) external payable {
        require(state == State.PAYING_OUT);
        require(participants[msg.sender].exists);

        // TODO: validate our identity token

        // TODO: return calculated dividend to participant
    }

    // Remove a participant from the tontine and devolve their share to surviving participants
    function devolve(TontineStructs.Participant participant) internal {
        // TODO: emit event
        // TODO: remove a participant and divide their shares between remaining participants
        // TODO: if there is only one participant left, wrap up this contract
    }

    // The running tontine has devolved to the final participant
    // Wrap up the tontine and return all our funds to the originator
    function wrapUp(address _survivor) internal {
        // TODO: emit event

        // TODO: kill investment target
        // TODO: ensure investment has returned all funds
        selfdestruct(_survivor);
    }
}