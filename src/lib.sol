pragma solidity ^0.4.21;

// Common structs used across contracts
library TontineStructs {

    // Agreed on initial values of the tontine
    struct DeviceParameters {
        // The launch time of the tontine device
        uint launchTs;
        // The percent of returns to be paid out to participants in each payout cycle
        uint dividendPercent;
        // The address of the investment target to be agreed upon
        address investmentTarget;
    }

    // A participant in the tontine
    struct Participant {
        // The address of the participant
        address addr;
        // The total amount of money invested in the tontine
        uint invested;
        // boolean flag to determine if they exist in a map
        bool exists;
    }
}