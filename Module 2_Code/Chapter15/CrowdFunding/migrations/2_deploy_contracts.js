var CrowdFunding = artifacts.require("./CrowdFunding.sol");

module.exports = (deployer, network, accounts) => {
  const ownerAddress = accounts[0];
  deployer.deploy(CrowdFunding, ownerAddress, 30, 60, "smartchart", "smartchart.tech");
}
