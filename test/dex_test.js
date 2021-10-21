const Dex = artifacts.require("Dex")
const Link = artifacts.require("Link")
const truffleAssert = require('truffle-assertions');

contract("Dex", accounts => {
      it("should require user to have sufficient ETH deposited to create a LIMIT BUY order", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await link.approve(dex.address, 100);
          await dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]});
          await dex.depositTokens(100, web3.utils.fromUtf8("LINK"));
          await dex.depositEth({from: accounts[0], value: 100});
          await dex.depositEth({from: accounts[1], value: 100});
          await dex.depositEth({from: accounts[2], value: 100});
          await truffleAssert.reverts(dex.createLimitOrder(true, web3.utils.fromUtf8("LINK"), 100, 2, {from:accounts[1]}))
          await truffleAssert.passes(dex.createLimitOrder(true, web3.utils.fromUtf8("LINK"), 100, 1, {from: accounts[1]}))
      })

      it("should require user to have sufficient tokens deposited to create a SELL order", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await truffleAssert.reverts(dex.createLimitOrder(false, web3.utils.fromUtf8("LINK"), 100, 1, {from: accounts[1]}))
          await truffleAssert.passes(dex.createLimitOrder(false, web3.utils.fromUtf8("LINK"), 100, 1, {from: accounts[0]}))
          let accounts_0_balance = await dex.ethBalance(accounts[0]);
          assert.equal(accounts_0_balance.toNumber(), 200)
          let accounts_1_tokens = await dex.tokenBalances(accounts[1], web3.utils.fromUtf8("LINK"))
          assert.equal(accounts_1_tokens.toNumber(), 100)
      })
      it("should store BUY LIMIT orders from highest price to lowest price", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await dex.createLimitOrder(true, web3.utils.fromUtf8("LINK"), 25, 2, {from:accounts[2]})
          await dex.createLimitOrder(true, web3.utils.fromUtf8("LINK"), 25, 1, {from:accounts[0]})
          await dex.createLimitOrder(true, web3.utils.fromUtf8("LINK"), 25, 3, {from:accounts[0]})
          let buyOrderbook = await dex.getBuyOrders();
          assert(buyOrderbook.length > 0);
          for (let i = 0; i < buyOrderbook.length - 1; i++) {
            assert(buyOrderbook[i].price >= buyOrderbook[i+1].price, "not right order in buy book")
          }
      })

      it("should assign a unique ID to all orders", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          let buyOrderbook = await dex.getBuyOrders();
          assert(buyOrderbook.length > 0);
          for (let i = 0; i < buyOrderbook.length - 1; i++) {
            assert(buyOrderbook[i].txID != buyOrderbook[i+1].txID, "txID's should be unique")
          }
      })

      it("should fill MARKET orders first", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await dex.createMarketOrder(true, web3.utils.fromUtf8("LINK"), 10, {from:accounts[2]})
          await dex.createLimitOrder(false, web3.utils.fromUtf8("LINK"), 10, 1, {from:accounts[1]})
          let buyOrderbook = await dex.getBuyOrders();
          assert(buyOrderbook[0].price != 0)
          assert(buyOrderbook.length == 3)
      })

      it("should handle transfers of ETH and Tokens properly", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          let accounts_0_balance = await dex.ethBalance(accounts[0])
          let accounts_1_balance = await dex.ethBalance(accounts[1])
          let accounts_2_balance = await dex.ethBalance(accounts[2])
          assert.equal(accounts_0_balance, 200)
          assert.equal(accounts_1_balance, 10)
          assert.equal(accounts_2_balance, 90)
          let accounts_0_tokens = await dex.tokenBalances(accounts[0], web3.utils.fromUtf8("LINK"))
          let accounts_1_tokens = await dex.tokenBalances(accounts[1], web3.utils.fromUtf8("LINK"))
          let accounts_2_tokens = await dex.tokenBalances(accounts[2], web3.utils.fromUtf8("LINK"))
          assert.equal(accounts_0_tokens, 0)
          assert.equal(accounts_1_tokens, 90)
          assert.equal(accounts_2_tokens, 10)
      })

      it("should remove filled orders from storage", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()

          await dex.createMarketOrder(false, web3.utils.fromUtf8("LINK"), 75, {from:accounts[1]})
          let buyOrderbook = await dex.getBuyOrders();
          assert.equal(buyOrderbook.length, 0)
          let sellOrderbook = await dex.getSellOrders();
          assert.equal(sellOrderbook.length, 0)

          // let accounts_0_balance = await dex.ethBalance(accounts[0])
          // let accounts_1_balance = await dex.ethBalance(accounts[1])
          // let accounts_2_balance = await dex.ethBalance(accounts[2])
          // assert.equal(accounts_0_balance.toNumber(), 100)
          // assert.equal(accounts_1_balance.toNumber(), 160)
          // assert.equal(accounts_2_balance.toNumber(), 40)
          // let accounts_0_tokens = await dex.tokenBalances(accounts[0], web3.utils.fromUtf8("LINK"))
          // let accounts_1_tokens = await dex.tokenBalances(accounts[1], web3.utils.fromUtf8("LINK"))
          // let accounts_2_tokens = await dex.tokenBalances(accounts[2], web3.utils.fromUtf8("LINK"))
          // assert.equal(accounts_0_tokens, 50)
          // assert.equal(accounts_1_tokens, 15)
          // assert.equal(accounts_2_tokens, 35)
      })

      it("should store SELL LIMIT orders from lowest price to highest price", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await dex.createLimitOrder(false, web3.utils.fromUtf8("LINK"), 20, 2, {from:accounts[0]})
          await dex.createLimitOrder(false, web3.utils.fromUtf8("LINK"), 20, 1, {from:accounts[0]})
          await dex.createLimitOrder(false, web3.utils.fromUtf8("LINK"), 20, 3, {from:accounts[0]})
          let sellOrderbook = await dex.getSellOrders();
          for (let i = 0; i < sellOrderbook.length - 1; i++) {
            assert(sellOrderbook[i].price <= sellOrderbook[i+1].price, "not right order in sell book")
          }
      })

      it("should reject transactions if buyer does not have sufficient ETH deposited", async () => {
          let dex = await Dex.deployed()
          let link = await Link.deployed()
          await truffleAssert.reverts(dex.createLimitOrder(true, web3.utils.fromUtf8("LINK"), 40, 2, {from:accounts[2]}))
      })

})
