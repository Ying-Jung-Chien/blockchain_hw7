pragma solidity ^0.8.9;

import "./Token.sol";

contract TokenFactory {
    mapping(address => uint256) private _exchangeRates;
    mapping(string => address) private _tokenAddresses;

    event ValuePrinted(uint256 value);

    function createToken(
        string memory name,
        string memory symbol,
        uint256 exchangeRate,
        uint256 initialSupply
    ) public {
        Token newToken = new Token(name, symbol, msg.sender, initialSupply);
        address newTokenAddress = address(newToken);
        _exchangeRates[newTokenAddress] = exchangeRate;
        _tokenAddresses[name] = newTokenAddress;
    }

    function getTokenExchangeRate(address tokenAddress) public view returns (uint256) {
        return _exchangeRates[tokenAddress];
    }
    
    function getTokenAddress(string memory name) public view returns (address) {
        return _tokenAddresses[name];
    }

    function getTokenName(address tokenAddress) public view returns (string memory) {
        Token _token = Token(tokenAddress);
        return _token.name();
    }

    function getTokenSymbol(address tokenAddress) public view returns (string memory) {
        Token _token = Token(tokenAddress);
        return _token.symbol();
    }

    function getTokenTotalSupply(address tokenAddress) public view returns (uint256) {
        Token _token = Token(tokenAddress);
        return _token.totalSupply();
    }

    function getTokenBalanceOf(address tokenAddress) public view returns (uint256) {
        Token _token = Token(tokenAddress);
        return _token.balanceOf(msg.sender);
    }

    function getTokenDecimals(address tokenAddress) public view returns (uint256) {
        Token _token = Token(tokenAddress);
        return _token.decimals();
    }

    function exchangeEtherForToken(address tokenAddress) public payable {
        require(_exchangeRates[tokenAddress] > 0, "Token not found");
        uint256 amount = (msg.value * _exchangeRates[tokenAddress]) / 1 ether;
        Token _token = Token(tokenAddress);
        _token.transfer(msg.sender, amount);
    }

    function sendToken(address recipient, address tokenAddress, uint256 amount) public {
        Token _token = Token(tokenAddress);
        require(_token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        _token.transferFrom(msg.sender, recipient, amount);
    }
}