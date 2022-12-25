// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AAPL.sol";
import "./MSFT.sol";


contract TokenSwap {
    address payable admin;
    //ratioAX is the percentage of how much TokenA is worth of TokenX
    uint256 ratioAX;
    bool AcheaperthenX;
    uint256 fees;
    TokenAAPLMCF public tokenAAPLMCF;
    TokenMSFTMCF public tokenMSFTMCF;

    constructor(address _tokenAAPLMCF, address _tokenMSFTMCF) {
        admin = payable(msg.sender);
        tokenAAPLMCF = TokenAAPLMCF(_tokenAAPLMCF);
        tokenMSFTMCF = TokenMSFTMCF(_tokenMSFTMCF);
        //due to openzeppelin implementation, transferFrom function implementation expects _msgSender() to be the beneficiary from the caller
        // but in this use cae we are using this contract to transfer so its always checking the allowance of SELF
        tokenAAPLMCF.approve(address(this), tokenAAPLMCF.totalSupply());
        tokenMSFTMCF.approve(address(this), tokenAAPLMCF.totalSupply());
    }

    modifier onlyAdmin() {
        payable(msg.sender) == admin;
        _;
    }

    function setRatio(uint256 _ratio) public onlyAdmin {
        ratioAX = _ratio;
    }

    function getRatio() public view onlyAdmin returns (uint256) {
        return ratioAX;
    }

    function setFees(uint256 _Fees) public onlyAdmin {
        fees = _Fees;
    }

    function getFees() public view onlyAdmin returns (uint256) {
        return fees;
    }

    // accepts amount of tokenAAPLMCF and exchenge it for tokenMSFTMCF, vice versa with function swapTKX
    // transfer tokensABC from sender to smart contract after the user has approved the smart contract to
    // withdraw amount TKA from his account, this is a better solution since it is more open and gives the
    // control to the user over what calls are transfered instead of inspecting the smart contract
    // approve the caller to transfer one time from the smart contract address to his address
    // transfer the exchanged tokenMSFTMCF to the sender
    function swapTKA(uint256 amountTKA) public returns (uint256) {
        //check if amount given is not 0
        // check if current contract has the necessary amout of Tokens to exchange
        require(amountTKA > 0, "amountTKA must be greater then zero");
        require(
            tokenAAPLMCF.balanceOf(msg.sender) >= amountTKA,
            "sender doesn't have enough Tokens"
        );

        uint256 exchangeA = uint256(mul(amountTKA, ratioAX));
        uint256 exchangeAmount = exchangeA -
            uint256((mul(exchangeA, fees)) / 100);
        require(
            exchangeAmount > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            tokenMSFTMCF.balanceOf(address(this)) > exchangeAmount,
            "currently the exchange doesnt have enough XYZ Tokens, please retry later :=("
        );

        tokenAAPLMCF.transferFrom(msg.sender, address(this), amountTKA);
        tokenMSFTMCF.approve(address(msg.sender), exchangeAmount);
        tokenMSFTMCF.transferFrom(
            address(this),
            address(msg.sender),
            exchangeAmount
        );
        return exchangeAmount;
    }

    function swapTKX(uint256 amountTKX) public returns (uint256) {
        //check if amount given is not 0
        // check if current contract has the necessary amout of Tokens to exchange and the sender
        require(amountTKX >= ratioAX, "amountTKX must be greater then ratio");
        require(
            tokenMSFTMCF.balanceOf(msg.sender) >= amountTKX,
            "sender doesn't have enough Tokens"
        );

        uint256 exchangeA = amountTKX / ratioAX;
        uint256 exchangeAmount = exchangeA - ((exchangeA * fees) / 100);

        require(
            exchangeAmount > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            tokenAAPLMCF.balanceOf(address(this)) > exchangeAmount,
            "currently the exchange doesnt have enough XYZ Tokens, please retry later :=("
        );
        tokenMSFTMCF.transferFrom(msg.sender, address(this), amountTKX);
        tokenAAPLMCF.approve(address(msg.sender), exchangeAmount);
        tokenAAPLMCF.transferFrom(
            address(this),
            address(msg.sender),
            exchangeAmount
        );
        return exchangeAmount;
    }

    //leting the Admin of the TokenSwap to buyTokens manually is preferable and better then letting the contract
    // buy automatically tokens since contracts are immutable and in case the value of some tokens beomes
    // worthless its better to not to do any exchange at all
    function buyTokensABC(uint256 amount) public payable onlyAdmin {
        tokenAAPLMCF.buyTokens{value: msg.value}(amount);
    }

    function buyTokensXYZ(uint256 amount) public payable onlyAdmin {
        tokenMSFTMCF.buyTokens{value: msg.value}(amount);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

