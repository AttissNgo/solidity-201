const Dex = artifacts.require("Dex")
const Link = artifacts.require("Link")
const truffleAssert = require('truffle-assertions');

contract("Dex", accounts => {
      it("should only be possible for owner to add tokens", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await truffleAssert.passes(
            dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]})
          )
          await truffleAssert.reverts(
            dex.addToken(web3.utils.fromUtf8("TEST"), link.address, {from: accounts[1]})
          )
      })
      it("should handle token deposits correctly", async () => {
          let dex = await Dex.deployed() //needs these variables declared every time
          let link = await Link.deployed()
          await link.approve(dex.address, 100);
          await dex.depositTokens(100, web3.utils.fromUtf8("LINK"));
          let balance = await dex.tokenBalances(accounts[0], web3.utils.fromUtf8("LINK"))
          //we have to create the balance variable because the call is asynchronous
          //and we want to use the mocha 'assert' function on it
          assert.equal(balance.toNumber(), 100) // have to use 'toNumber()' to convert from BN
      })
      it("should handle token withdrawals correctly", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await truffleAssert.reverts(dex.withdrawTokens(101, web3.utils.fromUtf8("LINK")))
          await truffleAssert.passes(dex.withdrawTokens(100, web3.utils.fromUtf8("LINK")))
      })
      it("should handle ETH deposits correctly", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await dex.depositEth({value: 1});
          let ethBalance = await dex.ethBalance(accounts[0])
          assert.equal(ethBalance, 1)
      })
      it("should handle ETH withdrawals correctly", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await truffleAssert.reverts(dex.withdrawEth(2))
          await truffleAssert.passes(dex.withdrawEth(1))
          let ethZeroBalance = await dex.ethBalance(accounts[0])
          assert.equal(ethZeroBalance, 0)
      })

})
