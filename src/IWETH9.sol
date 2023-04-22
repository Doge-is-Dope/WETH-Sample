// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWETH9 {
    /// @notice This event should be emitted when deposit is called.
    event Deposit(address indexed dest, uint256 wad);

    /// @notice This event should be emitted when withdraw is called.
    event Withdrawal(address indexed src, uint256 wad);

    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256 _amount) external;
}
