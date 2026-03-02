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
    mapping(address => Plan[]) private merchantPlans;
    error ZeroPrice();
    error ZeroInterval();

    constructor() {}

    function createPlan(address _token, uint256 _price, uint256 _interval) external {
        if (_price == 0) {
            revert ZeroPrice();
        }
        if (_interval == 0) {
            revert ZeroInterval();
        }

        Plan memory plan = Plan({merchant: msg.sender, token: _token, price: _price, interval: _interval, active: true});

        merchantPlans[msg.sender].push(plan);
    }

    function getPlan(uint256 planId)
        external
        view
        returns (address merchant, address token, uint256 price, uint256 interval, bool active)
    {
        Plan storage plan = merchantPlans[merchant][planId];

        return (plan.merchant, plan.token, plan.price, plan.interval, plan.active);
    }
}
