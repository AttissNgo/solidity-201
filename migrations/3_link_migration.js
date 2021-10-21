const Link = artifacts.require("Link");
const Dex = artifacts.require("Dex");

module.exports =  async function(deployer) {
    await deployer.deploy(Link);

    // let dex = await Dex.deployed() // create an instance so we can call wallet functions in this migration
    // let link = await Link.deployed()
    // await link.approve(dex.address, 1000) // call approve function from Link - approve address of Wallet contract
    // dex.addToken(web3.utils.fromUtf8("LINK"), link.address)
    // await dex.depositTokens(1000, web3.utils.fromUtf8("LINK"))


    // let balanceOfLink = await dex.balances(accounts[0], web3.utils.fromUtf8("LINK"));
    // console.log(balanceOfLink);

};
