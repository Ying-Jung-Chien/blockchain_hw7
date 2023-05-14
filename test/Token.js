const { expect } = require("chai");

describe("Token", function () {
  let TokenFactory;
  let tokenFactory;
  let users;

  beforeEach(async () => {
    TokenFactory = await ethers.getContractFactory("TokenFactory");
    users = await ethers.getSigners();
    tokenFactory = await TokenFactory.deploy();
  });

  it("should create a new token", async function () {
    const name = "Token 1";
    const symbol = "TK1";
    const exchangeRate = 100;
    const initialSupply = 100;

    await tokenFactory.connect(users[0]).createToken(name, symbol, exchangeRate, initialSupply);
    const tokenAddress = await tokenFactory.getTokenAddress(name);
    const tokenName = await tokenFactory.getTokenName(tokenAddress);
    const tokenSymbol = await tokenFactory.getTokenSymbol(tokenAddress);
    const tokenBalanceOf = await tokenFactory.connect(users[0]).getTokenBalanceOf(tokenAddress);
    const tokenDecimals = await tokenFactory.getTokenDecimals(tokenAddress);
    const tokenExchangeRate = await tokenFactory.getTokenExchangeRate(tokenAddress);

    expect(tokenName).to.equal(name);
    expect(tokenSymbol).to.equal(symbol);
    expect(tokenExchangeRate).to.equal(exchangeRate);
    expect(tokenBalanceOf).to.equal(initialSupply * 10**tokenDecimals);
  });

  it("should exchange Ether for tokens", async function () {
    const name = "Token 1";
    const symbol = "TK1";
    const exchangeRate = 100;
    const initialSupply = 1000;

    await tokenFactory.connect(users[0]).createToken(name, symbol, exchangeRate, initialSupply);

    const tokenAddress = await tokenFactory.getTokenAddress(name);
    const tokenBalanceBefore = await tokenFactory.connect(users[1]).getTokenBalanceOf(tokenAddress);

    const etherAmount = ethers.utils.parseEther("1");
    await tokenFactory.connect(users[1]).exchangeEtherForToken(tokenAddress, { value: etherAmount });
    
    const tokenBalanceAfter = await tokenFactory.connect(users[1]).getTokenBalanceOf(tokenAddress);

    expect(tokenBalanceAfter).to.equal(tokenBalanceBefore.add(exchangeRate));
  });

  it("should send tokens to another user", async function () {
    const name = "Token 1";
    const symbol = "TK1";
    const exchangeRate = 100;
    const initialSupply = 1;


    await tokenFactory.connect(users[0]).createToken(name, symbol, exchangeRate, initialSupply);

    const tokenAddress = await tokenFactory.getTokenAddress(name);
    const tokenBalanceOf = await tokenFactory.connect(users[0]).getTokenBalanceOf(tokenAddress);

    const recipient = users[1].address;
    const amount = tokenBalanceOf/2;
    
    const token = await ethers.getContractAt("Token", tokenAddress);
    await token.connect(users[0]).approve(tokenFactory.address, amount);
    await tokenFactory.connect(users[0]).sendToken(recipient, tokenAddress, amount);

    const senderBalance = await tokenFactory.connect(users[0]).getTokenBalanceOf(tokenAddress);
    const recipientBalance = await tokenFactory.connect(users[1]).getTokenBalanceOf(tokenAddress);

    expect(senderBalance).to.equal(amount);
    expect(recipientBalance).to.equal(amount);
  });
});