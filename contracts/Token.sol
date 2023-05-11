pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => uint256) private _exchangeRates;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function decimals() override public view returns (uint8) {
        return 5;
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint256 exchangeRate
    ) public {
        Token newToken = new Token(name, symbol);
        address newTokenAddress = address(newToken);
        _exchangeRates[newTokenAddress] = exchangeRate;
        _mint(address(this), 10000 * 10**5);
    }

    function getTokenExchangeRate(address tokenAddress) public view returns (uint256) {
        return _exchangeRates[tokenAddress];
    }

    function exchangeEtherForToken(address tokenAddress) public payable {
        require(_exchangeRates[tokenAddress] > 0, "Token not found");
        uint256 amount = (msg.value * _exchangeRates[tokenAddress]) / 1 ether;
        _balances[msg.sender][tokenAddress] += amount;
        _transfer(address(this), msg.sender, amount);
    }

    function sendToken(address recipient, address tokenAddress, uint256 amount) public {
        require(_balances[msg.sender][tokenAddress] >= amount, "Insufficient balance");
        _token = IERC20(tokenAddress);
        _balances[msg.sender][tokenAddress] -= amount;
        _balances[recipient][tokenAddress] += amount;
        _token.transferFrom(msg.sender, recipient, amount);
    }
}