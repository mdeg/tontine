pragma solidity ^0.4.21;

// Common structs used across contracts
library TontineLib {

    // Fixed point multiplication constant
    uint256 constant FIXED_POINT_CONSTANT = 1000000000000000000;
    function getFixedPointConstant() public pure returns (uint256) { return FIXED_POINT_CONSTANT; }

    // Agreed on initial values of the tontine
    struct DeviceParameters {
        // The launch time of the tontine device
        uint launchTs;
        // The percent of returns to be paid out to participants in each payout cycle
        uint dividendPercent;
        // The address of the investment target to be agreed upon
        address investmentTarget;
    }
}