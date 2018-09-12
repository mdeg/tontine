pragma solidity ^0.4.21;

import "./lib.sol";
import "./participant.sol" as ParticipantContract;
import "./investment.sol";

contract RunningTontine {

    uint constant ONE_YEAR_IN_SECONDS = 31536000;

    struct Participant {
        // The share the participant holds in the tontine
        uint256 share;

        // Whether the participant has collected their share in this run
        bool hasCollected;

        // Whether the participant is still a valid member of the tontine
        bool remains;

        // Gimmicky flag to determine if it exists in the mapping
        bool exists;
    }

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
    address investmentAddress;

    // The timestamp we used on launch
    uint launchTs;

    // The interval until the next payout in seconds
    uint payoutIntervalInSeconds;

    // The period of time participants have to collect their money
    uint payoutPeriod;

    // Mapping of the share of all current participants in the tontine
    // A non-zero value here implies that a participant is still in the tontine
    mapping ( address => Participant ) participants;

    // Iterable list of addresses of all participants
    // To prevent traversals, participants are NOT removed when devolved - check remains flag instead
    address[] public participantsList;

    // Participant count to allow traversal
    uint numParticipants = 0;

    // Number of ACTIVE participants - again, prevent traversals
    uint numActiveParticipants = 0;

    // The pot of money taken from participants that have been devolved
    uint pot = 0;

    // Addresses that have been verified and their identity tokens
    mapping ( address => bytes32 ) verifiedIdentities;

    constructor(address _investmentAddress) public {
        launchTs = now;
        investmentAddress = _investmentAddress;

        payoutIntervalInSeconds = launchTs + ONE_YEAR_IN_SECONDS;

        // Seed the investment target with our initial investment
        investmentAddress.transfer(address(this).balance);
    }

    // TODO: work out how to timer this
    function endPayoutPeriod() public {
        // TODO: require the message comes from the timer
        require(state == State.PAYING_OUT);

        // Expire any participants that have not collected
        for (uint i = 0; i < numParticipants; i++) {
            if (!participants[participantsList[i]].hasCollected) {
                devolve(participantsList[i]);
            }
            participants[participantsList[i]].hasCollected = false;
        }

        // Return any uncollected dividends to the investment pool
        investmentAddress.transfer(address(this).balance);

        state = State.INVESTING;
    }

    // Receive dividends from the investment contract
    function receiveReturnOnInvestment() external payable {
        require(msg.sender == investmentAddress);
        state = State.PAYING_OUT;

        uint expiry = now + payoutPeriod;

        // Notify all surviving participants that their funds are ready to collect
        for (uint i = 0; i < numParticipants; i++) {
            if (participants[participantsList[i]].remains) {
                ParticipantContract.Participant(participantsList[i]).notify(expiry);

            }
        }
    }

    // Add a new participant to the running tontine
    function addParticipant(address _participant, uint256 _share) external {
        require(msg.sender == initialTontineAddress);

        participants[_participant] = Participant({
            share: _share,
            hasCollected: false,
            remains: true,
            exists: true
        });
        participantsList.push(_participant);
        numParticipants++;
        numActiveParticipants++;
    }

    // Called by a participant attempting to retrieve funds from this running tontine
    function retrieve(bytes32 identityToken) external payable {
        require(state == State.PAYING_OUT);
        require(participants[msg.sender].exists);

        // Verify that we have an identity token and it matches
        require(identityToken == verifiedIdentities[msg.sender]);

        // Calculate the dividend - their original share plus their bonus share of the empty pot
        uint originalShare = address(this).balance / participants[msg.sender].share;
        uint bonus = pot / numActiveParticipants;

        // Return` the users' calculated dividend
        msg.sender.transfer(originalShare + bonus);
    }

    // Remove a participant from the tontine and devolve their share to surviving participants
    function devolve(address participant) internal {

        emit Devolve(participant);

        // Notify the participant contract they have been cut out of the contract
        ParticipantContract.Participant(participantsList[i]).devolve();

        // Modify their remnant flag
        participants[participant].remains = false;

        // Move their share to the pot
        pot += participants[participant].share;
        participants[participant].share = 0;

        // Remove them from the active participant count
        numActiveParticipants--;

        // If there's only one active participant left, it's time to wrap up the contract
        if (numActiveParticipants == 1) {
            // Can't tell who's active and who's not, so traverse
            // TODO: do we need to avoid the traversal?
            for (uint i = 0; i < numParticipants; i++) {
                if (participants[participantsList[i]].remains) {
                    wrapUp(participantsList[i]);
                }
            }
        }
    }

    // The running tontine has devolved to the final participant
    // Wrap up the tontine and return all our funds to the originator
    function wrapUp(address _survivor) internal {
        emit WrapUp(_survivor, now);

        Investment(investmentAddress).end();

        // Bye!
        selfdestruct(_survivor);
    }

    event Devolve(address);
    event WrapUp(address survivor, uint ts);
}