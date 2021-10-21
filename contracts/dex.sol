pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./wallet.sol";

contract Dex is Wallet {
    using SafeMath for uint256;

    struct Order {
        uint txID;
        address trader;
        bytes32 ticker;
        uint amount;
        uint price;
    }

    uint nextID = 0;

    Order[] buyOrders;
    Order[] sellOrders;

    function getBuyOrders() public view returns(Order[] memory) {
        return buyOrders;
    }
    function getSellOrders() public view returns(Order[] memory) {
        return sellOrders;
    }

    function createLimitOrder(bool _isBuyOrder, bytes32 ticker, uint _amount, uint _price) public {
        require(_price > 0, "price must be higher than 0");
        if(_isBuyOrder == true){
            require(ethBalance[msg.sender] >= _amount.mul(_price));
            buyOrders.push(Order(nextID, msg.sender, ticker, _amount, _price));
            uint i = buyOrders.length > 0 ? buyOrders.length - 1 : 0;
            while (i > 0){
                if((buyOrders[i].price < buyOrders[i-1].price) || buyOrders[i-1].price == 0){
                    break;
                }
                else {
                    Order memory temp = buyOrders[i-1];
                    buyOrders[i-1] = buyOrders[i];
                    buyOrders[i] = temp;
                    i--;
                }
            }
            fillBuyOrders();
        }
        else if(_isBuyOrder == false){
            require(tokenBalances[msg.sender][ticker] >= _amount);
            sellOrders.push(Order(nextID, msg.sender, ticker, _amount, _price));
            uint i = sellOrders.length > 0 ? sellOrders.length - 1 : 0;
            while(i > 0){
                if((sellOrders[i].price > sellOrders[i-1].price) || sellOrders[i-1].price == 0){
                    break;
                }
                else {
                    Order memory temp = sellOrders[i-1];
                    sellOrders[i-1] = sellOrders[i];
                    sellOrders[i] = temp;
                    i--;
                }
            }
            fillBuyOrders();
        }
        nextID++;
    }

    function createMarketOrder(bool _isBuyOrder, bytes32 ticker, uint _amount) public {
        if(_isBuyOrder == true){
            buyOrders.push(Order(nextID, msg.sender, ticker, _amount, 0));
            uint i = buyOrders.length > 0 ? buyOrders.length - 1 : 0;
            while(i > 0){
                if(buyOrders[i-1].price == 0){
                    break;
                }
                else {
                    Order memory temp = buyOrders[i-1];
                    buyOrders[i-1] = buyOrders[i];
                    buyOrders[i] = temp;
                    i--;
                }
            }
            fillSellOrders();
        }
        else if(_isBuyOrder == false) {
            sellOrders.push(Order(nextID, msg.sender, ticker, _amount, 0));
            uint i = sellOrders.length > 0 ? sellOrders.length - 1 : 0;
            while(i > 0){
                if(sellOrders[i-1].price == 0){
                    break;
                }
                else {
                    Order memory temp = sellOrders[i-1];
                    sellOrders[i-1] = sellOrders[i];
                    sellOrders[i] = temp;
                    i--;
                }
            }
            fillSellOrders();
        }
        nextID++;
    }

    function fillBuyOrders() private {
        for(uint i = 0; i < buyOrders.length; i++){
            for(uint j = 0; j < sellOrders.length; j++){
                if(buyOrders[i].ticker == sellOrders[j].ticker) {

                    uint amountTokens;
                    uint txPrice;

                    if(buyOrders[i].price == 0 && sellOrders[j].price != 0){
                        txPrice = sellOrders[j].price;
                    }
                    else if((buyOrders[i].price != 0 && sellOrders[j].price == 0) ||
                            (buyOrders[i].price != 0 && buyOrders[i].price == sellOrders[j].price)
                            ){
                        txPrice = buyOrders[j].price;
                    }
                    else {
                        break;
                    }

                    if(buyOrders[i].amount <= sellOrders[j].amount){
                        amountTokens = buyOrders[i].amount;
                    }
                    else if(buyOrders[i].amount > sellOrders[j].amount) {
                        amountTokens = sellOrders[j].amount;
                    }

                    uint totalPrice = amountTokens * txPrice;

                    buyOrders[i].amount = buyOrders[i].amount.sub(amountTokens);
                    sellOrders[j].amount = sellOrders[j].amount.sub(amountTokens);

                    executeTrade(buyOrders[i].trader, sellOrders[j].trader, buyOrders[i].ticker, amountTokens, totalPrice);
                }
            }
        }
        arrangeOrderbook();
    }

    function fillSellOrders() private {
        for(uint i = 0; i < sellOrders.length; i++){
            for(uint j = 0; j < buyOrders.length; j++){
                if(sellOrders[i].ticker == buyOrders[j].ticker) {

                    uint amountTokens;
                    uint txPrice;


                    if(sellOrders[i].price == 0 && buyOrders[j].price != 0) {
                        txPrice = buyOrders[j].price;
                    }

                    else if((sellOrders[i].price != 0 && buyOrders[j].price == 0) ||
                            (sellOrders[i].price != 0 && sellOrders[i].price == buyOrders[j].price)
                            ){
                        txPrice = sellOrders[i].price;
                    }
                    else {
                        break;
                    }

                    if(sellOrders[i].amount <= buyOrders[j].amount){
                        amountTokens = sellOrders[i].amount;
                    }
                    else if(sellOrders[i].amount > buyOrders[j].amount){
                        amountTokens = buyOrders[j].amount;
                    }

                    uint totalPrice = amountTokens * txPrice;

                    sellOrders[i].amount = sellOrders[i].amount.sub(amountTokens);
                    buyOrders[j].amount = buyOrders[j].amount.sub(amountTokens);

                    executeTrade(buyOrders[j].trader, sellOrders[i].trader, sellOrders[i].ticker, amountTokens, totalPrice);
                }
            }
        }
        arrangeOrderbook();
    }

    function executeTrade(address buyer, address seller, bytes32 ticker, uint _amountTokens, uint _totalPrice) private {
        require(ethBalance[buyer] >= _totalPrice);
        require(tokenBalances[seller][ticker] >= _amountTokens);

        ethBalance[buyer] = ethBalance[buyer].sub(_totalPrice);
        ethBalance[seller] = ethBalance[seller].add(_totalPrice);
        tokenBalances[seller][ticker] = tokenBalances[seller][ticker].sub(_amountTokens);
        tokenBalances[buyer][ticker] = tokenBalances[buyer][ticker].add(_amountTokens);
    }

    function arrangeOrderbook() private {
        while(buyOrders.length > 0 && buyOrders[0].amount == 0){
            for(uint i = 0; i < buyOrders.length - 1; i++){
                buyOrders[i] = buyOrders[i+1];
            }
            buyOrders.pop();
        }
        while(sellOrders.length > 0 && sellOrders[0].amount == 0){
            for(uint i = 0; i < sellOrders.length - 1; i++){
                sellOrders[i] = sellOrders[i+1];
            }
            sellOrders.pop();
        }
    }
}
