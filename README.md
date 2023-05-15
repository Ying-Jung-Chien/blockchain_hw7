# HW7

## Environment - Hardhat
- [Tutorial](https://medium.com/my-blockchain-development-daily-journey/%E5%AE%8C%E6%95%B4%E7%9A%84hardhat%E5%AF%A6%E8%B8%90%E6%95%99%E7%A8%8B-a9b005aa4c12)
- Command
  ```
  # install dependencies
  npm install 
  ```
 
## Contract Code
### Voting
1. create poll (parameters: poll title/description/start time/end time/first proposal description)

    ```createPoll(string memory _title, string memory _description, uint _startTime, uint _endTime, string memory _proposalDescription)```

2. add proposal

    ```addProposal(uint pollId, string memory proposalDescription)```

3. check poll state (if now > start time: state = started elif now > ended time: state = ended)

    ```checkPolls()```

4. vote

    ```vote(uint pollId, uint proposalId)```

5. get resule (should check poll state first; would return the winner proposal description)

    ```getResult(uint pollId)```

### Token (TokenFactory.sol)
1. create a token

    ```createToken(string memory name, string memory symbol, uint256 exchangeRate, uint256 initialSupply)```

2. get token name

    ```getTokenName(address tokenAddress)```

3. get token symbol

    ```getTokenSymbol(address tokenAddress)```

4. get token exchange rate

    ```getTokenExchangeRate(address tokenAddress)```

5. get token address

    ```getTokenAddress(string memory tokenName)```

6. get token total supply

    ```getTokenExchangeRate(address tokenAddress)```

7. get token balance of account (It checks the token balance in the caller's account)

    ```getTokenBalanceOf(address tokenAddress)```

8. get token decimals

    ```getTokenDecimals(address tokenAddress)```

9. convert ether to token (should pass: (tokenAddress, { value: etherAmount }))

    ```exchangeEtherForToken(address tokenAddress)```

10. send token to other user (should approve contract first, see test code below)

    ```sendToken(address recipient, address tokenAddress, uint256 amount)```

## Test Code
### Voting
- command

  ```npx hardhat test test/Voting.js```

- code
  ```
  const { expect } = require("chai");
  const { ethers } = require("hardhat");

  describe("Voting", function() {
    let accounts;
    let owner;
    let voting;

    beforeEach(async () => {
      accounts = await ethers.getSigners();
      owner = accounts[0];
      const Voting = await ethers.getContractFactory("Voting");
      voting = await Voting.deploy();
      await voting.deployed();
    });

    // test create poll and add proposal
    it("should allow adding options before poll starts", async function() {
      await voting.createPoll("Test Poll", "Test Description", Math.floor(Date.now() / 1000)  + 30, Math.floor(Date.now() / 1000) + 60, "Proposal 1");
      await voting.addProposal(0, "Proposal 2");
      const optionLength = await voting.getProposalLength(0);
      expect(optionLength.toNumber()).to.equal(2);
    });

    // check that state transitions are correct
    it("should start after startTime and end after endTime", async function() {
      await voting.createPoll("Test Poll", "Test Description", Math.floor(Date.now() / 1000)  + 10, Math.floor(Date.now() / 1000) + 30, "Proposal 1");
      await new Promise(resolve => setTimeout(resolve, 15000));
      await voting.checkPolls(); // should call checkPolls() first
      let poll = await voting.polls(0);
      expect(poll.ended).to.equal(false);

      await new Promise(resolve => setTimeout(resolve, 20000)); // wait for voting to end
      await voting.checkPolls();
      poll = await voting.polls(0);
      expect(poll.ended).to.equal(true);
    });

    // poll creator has a weight of 2, and must vote on the same proposal
    it("should have different weights between poll creator and usual voter", async function() {
      await voting.connect(owner).createPoll("Test Poll", "Test Description", Math.floor(Date.now() / 1000)  + 10, Math.floor(Date.now() / 1000) + 30, "Proposal 1");
      await voting.addProposal(0, "Proposal 2");

      await new Promise(resolve => setTimeout(resolve, 15000));
      await voting.connect(owner).vote(0, 0);
      await voting.connect(accounts[1]).vote(0, 0);
      await voting.connect(accounts[2]).vote(0, 1);
      await voting.connect(accounts[3]).vote(0, 1);

      await new Promise(resolve => setTimeout(resolve, 20000));
      await voting.checkPolls(); // should call checkPolls() first
      let winner = await voting.getResult(0);
      expect(winner).to.equal("Proposal 1");
    });
  });
  ```
## Token
- command

  ```npx hardhat test test/Token.js```

- code
  ```
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

    // test createToken
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

    // convert ether to token
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

    // send token to other user
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
      // contracts should first be approved to transfer tokens
      await token.connect(users[0]).approve(tokenFactory.address, amount);
      await tokenFactory.connect(users[0]).sendToken(recipient, tokenAddress, amount);

      const senderBalance = await tokenFactory.connect(users[0]).getTokenBalanceOf(tokenAddress);
      const recipientBalance = await tokenFactory.connect(users[1]).getTokenBalanceOf(tokenAddress);

      expect(senderBalance).to.equal(amount);
      expect(recipientBalance).to.equal(amount);
    });
  });
  ```
