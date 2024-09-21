// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Box} from "src/Box.sol";
import {GovToken} from "src/GovToken.sol";
import {MyGovernor} from "src/MyGoverner.sol";
import {TimeLock} from "src/TimeLock.sol";

contract MyGovernerTest is Test{
    MyGovernor governer;
    GovToken govToken;
    Box box;
    TimeLock timeLock;

    address public user = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600;
    // uint256 public constant VOTING_DELAY = 1;
    address[] proposers;
    address[] executors;
    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(user, INITIAL_SUPPLY);
        vm.startPrank(user);
        govToken.delegate(user);
        timeLock = new TimeLock(MIN_DELAY, proposers, executors);
        governer = new MyGovernor(govToken, timeLock);
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();
        timeLock.grantRole(proposerRole, address(governer));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, user);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernance() public{
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdateBox() public{
        uint256 valueToStore = 100;
        string memory description = "store 100 in box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        values.push(0);
        calldatas.push(encodedFunctionCall);
        targets.push(address(box));

        // 1. Propose to DAO
        uint256 proposalId = governer.propose(targets, values, calldatas, description);
        // View state
        console2.log("Proposal State:", uint256(governer.state(proposalId)));
        vm.warp(block.timestamp + governer.votingDelay() + 1);
        vm.roll(block.number + governer.votingDelay() + 1);
        console2.log("Proposal State:", uint256(governer.state(proposalId)));

        // 2. Vote
        string memory reason = "cuz it's better";
        uint8 support = 1;
        vm.prank(user);
        governer.castVoteWithReason(proposalId, support, reason);
        vm.warp(block.timestamp + governer.votingPeriod() + 1);
        vm.roll(block.number + governer.votingPeriod() + 1);
        console2.log("Proposal State:", uint256(governer.state(proposalId)));

        // 3. Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governer.queue(targets, values, calldatas, descriptionHash);
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);
        console2.log("Proposal State:", uint256(governer.state(proposalId)));

        // 4. Execute
        governer.execute(targets, values, calldatas, descriptionHash);

        assertEq(box.getNumber(), valueToStore);
    }
}