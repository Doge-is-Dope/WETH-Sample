// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/WETH.sol";

contract WETHTest is Test {
    WETH public weth;
    address user1;
    address user2;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Deposit(address indexed dest, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function setUp() public {
        weth = new WETH();
        user1 = address(0x123);
        user2 = address(0x456);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        weth.deposit{value: 1.2 ether}();
        uint balance = weth.balanceOf(user1); // Get the weth balance of user1

        // 測項 1. deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
        assertEq(balance, 1.2 ether);

        // 測項 2. deposit 應該將 msg.value 的 ether 轉入合約
        assertEq(address(weth).balance, 1.2 ether);

        // 測項 3: deposit 應該要 emit Deposit event
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, 1 ether);
        weth.deposit{value: 1 ether}();
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        weth.deposit{value: 1 ether}();

        // 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
        uint prevTotalSupply = weth.totalSupply();
        weth.withdraw(0.87 ether);
        assertEq(prevTotalSupply - weth.totalSupply(), 0.87 ether);

        // 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
        assertEq(user1.balance, 9.87 ether); // 10 - 1 + 0.87

        // 測項 6: withdraw 應該要 emit Withdraw event
        vm.expectEmit(true, true, false, true);
        emit Withdrawal(user1, 0.01 ether);
        weth.withdraw(0.01 ether);

        vm.stopPrank();
    }

    function testTransfer() public {
        vm.startPrank(address(this));
        weth.mint(10 ether); // mint 10 ether tokens to this contract

        // 測項 7: transfer 應該要將 erc20 token 轉給別人
        weth.transfer(user1, 1.23 ether); // transfer from contract to user1
        assertEq(weth.balanceOf(user1), 1.23 ether);

        vm.stopPrank();
    }

    function testApprove() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        weth.deposit{value: 1 ether}();

        // 測項 8: approve 應該要給他人 allowance
        weth.approve(user2, 0.87 ether);
        assertEq(weth.allowance(user1, user2), 0.87 ether);
        vm.stopPrank();
    }

    function testTransferFrom() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        weth.deposit{value: 5 ether}();
        weth.approve(user2, 3 ether);
        vm.stopPrank();

        // 測項 9: transferFrom 應該要可以使用他人的 allowance
        address user3 = address(0x789);
        vm.startPrank(user2);
        weth.transferFrom(user1, user3, 1.2 ether); // user2 sends 1.2 ether from user1 to user3 on behalf of user1
        assertEq(weth.balanceOf(user3), 1.2 ether);
        vm.stopPrank();

        // 測項 10: transferFrom 後應該要減除用完的 allowance
        assertEq(weth.allowance(user1, user2), 1.8 ether); // 3 - 1.2
    }

    // test mint
    function testMint() public {
        vm.startPrank(address(this));
        weth.mint(1.1 ether);
        assertEq(weth.balanceOf(address(this)), 1.1 ether);
        assertEq(weth.totalSupply(), 1.1 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Not the owner");
        weth.mint(1.123 ether);
        vm.stopPrank();
    }

    // test burn
    function testBurn() public {
        vm.startPrank(address(this));
        weth.mint(3 ether);
        weth.burn(1.234 ether);
        assertEq(weth.balanceOf(address(this)), 1.766 ether); // 3 - 1.234
        assertEq(weth.totalSupply(), 1.766 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Not the owner");
        weth.mint(1.123 ether);
        vm.stopPrank();
    }

    // test receive
    function testReceive() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        // test: deposit event should be emitted
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, 1.1 ether);

        (bool success, ) = address(weth).call{value: 1.1 ether}("");
        require(success);

        // test: check amount of eth and weth is correct
        assertEq(address(weth).balance, 1.1 ether); // weth has 1 ether
        assertEq(weth.balanceOf(user1), 1.1 ether); // user1 has 1 ether of weth
        assertEq(weth.totalSupply(), 1.1 ether); // mint 1 ether of weth

        vm.stopPrank();
    }
}
