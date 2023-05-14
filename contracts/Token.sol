pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => uint256) private _exchangeRates;
    mapping(string => uint256) private _tokenAddresses;

    constructor(string memory name, string memory symbol, address account, uint256 initialSupply) ERC20(name, symbol) {
        _mint(account, initialSupply * 10 ** uint(decimals()));
        _mint(msg.sender, initialSupply * 10 ** uint(decimals()));
    }

    function decimals() override public view returns (uint8) {
        return 5;
    }
}