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

  it("should allow adding options before poll starts", async function() {
    await voting.createPoll("Test Poll", "Test Description", Math.floor(Date.now() / 1000)  + 30, Math.floor(Date.now() / 1000) + 60, "Proposal 1");
    await voting.addProposal(0, "Proposal 2");
    const optionLength = await voting.getProposalLength(0);
    expect(optionLength.toNumber()).to.equal(2);
  });

  it("should start after startTime and end after endTime", async function() {
    await voting.createPoll("Test Poll", "Test Description", Math.floor(Date.now() / 1000)  + 10, Math.floor(Date.now() / 1000) + 30, "Proposal 1");
    await new Promise(resolve => setTimeout(resolve, 15000));
    await voting.checkPolls();
    let poll = await voting.polls(0);
    expect(poll.ended).to.equal(false);

    await new Promise(resolve => setTimeout(resolve, 20000));
    await voting.checkPolls();
    poll = await voting.polls(0);
    expect(poll.ended).to.equal(true);
  });

  it("should have different weights between poll creator and usual voter", async function() {
    await voting.connect(owner).createPoll("Test Poll", "Test Description", Math.floor(Date.now() / 1000)  + 10, Math.floor(Date.now() / 1000) + 30, "Proposal 1");
    await voting.addProposal(0, "Proposal 2");

    await new Promise(resolve => setTimeout(resolve, 15000));
    await voting.connect(owner).vote(0, 0);
    await voting.connect(accounts[1]).vote(0, 0);
    await voting.connect(accounts[2]).vote(0, 1);
    await voting.connect(accounts[3]).vote(0, 1);

    await new Promise(resolve => setTimeout(resolve, 20000));
    await voting.checkPolls();
    let winner = await voting.getResult(0);
    expect(winner).to.equal("Proposal 1");
  });
});