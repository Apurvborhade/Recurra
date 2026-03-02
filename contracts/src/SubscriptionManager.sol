// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IPlanRegistry {
    function getPlan(uint256 planId)
        external
        view
        returns (address merchant, address token, uint256 price, uint256 interval, bool active);
}

contract SubscriptionManager is ReentrancyGuard, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    IPlanRegistry public immutable planRegistry;
    uint256 public subscriptionCounter;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public userSubscriptions;

    error InvalidPlan();
    error InsufficientApprovedAmount();
    error SubscriptionNotActive();
    error SubScriptionAlreadyActive();
    error NotOwner();

    event Subscribed(uint256 indexed subscriptionId, address indexed user, uint256 indexed planId);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubscriptionPaused(uint256 indexed subscriptionId);
    event SubscriptionResumed(uint256 indexed subscriptionId);

    struct Subscription {
        address subscriber;
        uint256 planId;
        uint256 nextPaymentTime;
        uint256 approvedAmount;
        bool active;
    }

    constructor(address _planRegistry) {
        require(_planRegistry != address(0));

        planRegistry = IPlanRegistry(_planRegistry);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    // Subscribe
    function subscribe(uint256 planId, uint256 approvedAmount) external whenNotPaused nonReentrant returns (uint256) {
        (address merchant, address token, uint256 price, uint256 interval, bool active) = planRegistry.getPlan(planId);

        if (!active) {
            revert SubscriptionNotActive();
        }
        if (approvedAmount < price) {
            revert InsufficientApprovedAmount();
        }

        subscriptionCounter++;
        uint256 subId = subscriptionCounter;
        subscriptions[subId] = Subscription({
            subscriber: msg.sender,
            planId: planId,
            nextPaymentTime: block.timestamp + interval,
            approvedAmount: approvedAmount,
            active: true
        });

        userSubscriptions[msg.sender].push(subId);

        emit Subscribed(subId, msg.sender, planId);

        return subId;
    }

    // Cancel, Pause, Resume

    function cancelSubscription(uint256 subId) external nonReentrant {
        Subscription storage sub = subscriptions[subId];

        if (sub.subscriber != msg.sender) {
            revert NotOwner();
        }

        if (!sub.active) {
            revert SubscriptionNotActive();
        }

        sub.active = false;

        emit SubscriptionCancelled(subId);
    }

    function pauseSubscription(uint256 subId) external nonReentrant {
        Subscription storage sub = subscriptions[subId];

        if (sub.subscriber != msg.sender) {
            revert NotOwner();
        }

        if (!sub.active) {
            revert SubscriptionNotActive();
        }

        sub.active = false;

        emit SubscriptionPaused(subId);
    }

    function resumeSubscription(uint256 subId) external nonReentrant {
        Subscription storage sub = subscriptions[subId];

        if (sub.subscriber != msg.sender) {
            revert NotOwner();
        }

        if (sub.active) {
            revert SubScriptionAlreadyActive();
        }

        sub.active = true;

        emit SubscriptionResumed(subId);
    }

    // Validation and Payment Execution
    function validateExecution(uint256 subId)
        external
        view
        returns (address subscriber, uint256 planId, uint256 nextPaymentTime, uint256 approvedAmount, bool active)
    {
        Subscription memory sub = subscriptions[subId];

        if (!sub.active) {
            revert SubscriptionNotActive();
        }

        return (sub.subscriber, sub.planId, sub.nextPaymentTime, sub.approvedAmount, sub.active);
    }

    function updateNextPayment(uint256 subId, uint256 interval) external {
        Subscription storage sub = subscriptions[subId];

        if (!sub.active) {
            revert SubscriptionNotActive();
        }

        sub.nextPaymentTime += interval;
    }

    function pauseSystem() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpauseSystem() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
