// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IWETH9.sol";

contract WETH is IERC20, IERC20Metadata, IWETH9 {
    mapping(address => uint256) public balanceOf; // owner -> amount
    mapping(address => mapping(address => uint256)) public allowance; // owner -> sender(spender) -> amount

    uint256 public totalSupply; // total amount of tokens have been minted.
    uint8 public decimals; // decimals of the token
    address public owner; // the owner of the contract
    string public name; // name of the token
    string public symbol; // symbol of the token

    constructor() {
        name = "Wrapped Ether";
        symbol = "WETH";
        decimals = 18;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "Not enough to send"); // Check if the sender has enoungh amount
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount); // event Transfer is required
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "Not enough to send"); // Check if the sender has enoungh amount
        allowance[msg.sender][spender] = amount; // Set the allowance for spender
        emit Approval(msg.sender, spender, amount); // event Approval is required
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool success) {
        require(balanceOf[sender] >= amount);
        require(allowance[sender][msg.sender] >= amount);
        allowance[sender][msg.sender] -= amount; // this will be failed if the sender has no approval
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount); // event Transfer is required
        return true;
    }

    // Create tokens
    function mint(uint256 amount) external {
        require(msg.sender == owner, "Not the owner"); // Check if the caller is the owner of this contract
        balanceOf[msg.sender] += amount; // Allow anyone who call this function to mint a token
        totalSupply += amount;
        emit Transfer(address(0x0), msg.sender, amount); // event Transfer is required; the sender is 0x0
    }

    // Destroy tokens
    function burn(uint256 amount) external {
        require(msg.sender == owner, "Not the owner"); // Check if the caller is the owner of this contract
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0x0), amount); // event Transfer is required; the receiver is 0x0
    }

    // Deposit => Transfer [msg.value] amount of tokens to [msg.sender]
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0x0), msg.sender, msg.value);
    }

    // Withdraw => Transfer [_amount] of ethers to [msg.sender] and burn [_amount] of tokens
    function withdraw(uint256 _amount) external {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address(0x0), _amount);
    }

    // receive() => Same as deposit()
    receive() external payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0x0), msg.sender, msg.value);
    }
}
