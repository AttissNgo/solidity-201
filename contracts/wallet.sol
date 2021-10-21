pragma solidity 0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol"; //this one
// will be used to gain access to the IERC20 interface


contract Wallet is Ownable {
    using SafeMath for uint256;

    struct Token {
        bytes32 ticker;
        address tokenAddress; // the location of the token contract
    }

    bytes32[] public tokenList; //array to store list of tokens by ticker
    mapping(bytes32 => Token) public tokenMapping; // mapping to refer to a token object

    //mapping to store user's tokens - address(user) -> (ticker -> balance)
    mapping(address => mapping(bytes32 => uint256)) public tokenBalances;

    //mapping to store ether
    mapping(address => uint256) public ethBalance;

    modifier tokenExists(bytes32 ticker){
        require(tokenMapping[ticker].tokenAddress != address(0), "Token does not exist");
        _;
    }

    //function to add information about tokens to storage
    function addToken(bytes32 ticker, address tokenAddress) onlyOwner external {
        tokenMapping[ticker] = Token(ticker, tokenAddress); // creates a new token object
        // and assigns it to tokenMapping so it can be referred to by ticker
        tokenList.push(ticker); // add to list of token IDs
    }

    function depositTokens(uint amount, bytes32 ticker) tokenExists(ticker) external {
        //transfer FROM msg.sender to contract address
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        tokenBalances[msg.sender][ticker] = tokenBalances[msg.sender][ticker].add(amount);
    }

    function withdrawTokens(uint amount, bytes32 ticker) tokenExists(ticker) external {
        require(tokenBalances[msg.sender][ticker] >= amount, "Insufficient balance");
        tokenBalances[msg.sender][ticker] = tokenBalances[msg.sender][ticker].sub(amount);
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    }


    function transferTokens(address sender, address recipient, bytes32 ticker, uint256 amount) tokenExists(ticker) external {
        require(sender == msg.sender);
        require(tokenBalances[msg.sender][ticker] >= amount);

        tokenBalances[msg.sender][ticker] = tokenBalances[msg.sender][ticker].sub(amount);
        tokenBalances[recipient][ticker] = tokenBalances[recipient][ticker].add(amount);
    } //works

    function depositEth() payable external {
        ethBalance[msg.sender] = ethBalance[msg.sender].add(msg.value);
    }///YES! It works.

    function withdrawEth(uint amount) payable external {
        require(ethBalance[msg.sender] >= amount, "Insuffient balance");
        ethBalance[msg.sender] = ethBalance[msg.sender].sub(amount);
        payable(msg.sender).transfer(amount);
    }

    // @notice Will receive any eth sent to the contract
    // fallback () external payable {
    // }

}
