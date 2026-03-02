// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Struct
struct Plan {
    address merchant;
    address token;
    uint256 price;
    uint256 interval;
    bool active;
}

contract PlanRegistry {
    Plan[] public plans;

    error ZeroPrice();
    error ZeroInterval();

    constructor(address _merchant, address _token, uint256 _price, uint256 _interval) {
        if (_price == 0) {
            revert ZeroPrice();
        }
        if (_interval == 0) {
            revert ZeroInterval();
        }

        Plan memory plan1 = Plan({merchant: _merchant, token: _token, price: _price, interval: _interval, active: true});
        
        plans.push(plan1);
    }
}
