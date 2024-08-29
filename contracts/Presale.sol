// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Author: https://www.fiverr.com/s/xXAk8YQ

// import ownable from openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

contract Presale is Ownable(msg.sender) {
    // IERC20 token
    IERC20 public token;

    // payment tokens usdt and native token
    IERC20 public usdt;

    // Stage dates of 6 stages of presale. After each stage, the price of the token will increase. and Stage will be calculated by date
    uint256 public stage1;
    uint256 public stage2;
    uint256 public stage3;
    uint256 public stage4;
    uint256 public stage5;
    uint256 public stage6;

    // price of the token of each stage with token decimals
    uint256 public price1;
    uint256 public price2;
    uint256 public price3;
    uint256 public price4;
    uint256 public price5;
    uint256 public price6;

    // total tokens to be sold
    uint256 public totalTokens;

    // total tokens sold
    uint256 public soldTokens;

    // minimum and maximum tokens to be sold in each transaction
    uint256 public minTokens;
    uint256 public maxTokens;

    //  price aggregator
    AggregatorV3Interface internal dataFeed;

    // events
    event TokensSold(uint256 amount);
    event TokensBought(uint256 amount);

    // constructor setting all the values of the presale
    constructor(
        IERC20 _token,
        IERC20 _usdt,
        uint256 _stage1,
        uint256 _stage2,
        uint256 _stage3,
        uint256 _stage4,
        uint256 _stage5,
        uint256 _stage6,
        uint256 _price1,
        uint256 _price2,
        uint256 _price3,
        uint256 _price4,
        uint256 _price5,
        uint256 _price6,
        uint256 _totalTokens,
        uint256 _minTokens,
        uint256 _maxTokens,
        AggregatorV3Interface _dataFeed
    ) {
        token = _token;
        usdt = _usdt;
        stage1 = _stage1;
        stage2 = _stage2;
        stage3 = _stage3;
        stage4 = _stage4;
        stage5 = _stage5;
        stage6 = _stage6;
        price1 = _price1;
        price2 = _price2;
        price3 = _price3;
        price4 = _price4;
        price5 = _price5;
        price6 = _price6;
        totalTokens = _totalTokens;
        minTokens = _minTokens;
        maxTokens = _maxTokens;
        dataFeed = _dataFeed;
    }

    /*
        @des buy the tokens
        @param _amount amount of tokens to buy

     */
    function buy(uint256 _amount) public payable {
        require(_amount >= minTokens, "Amount is less than minimum tokens");
        require(_amount <= maxTokens, "Amount is more than maximum tokens");
        require(soldTokens + _amount <= totalTokens, "Not enough tokens left");
        uint256 price = getPrice();
        uint256 usdtAmount = (_amount * price) / 10 ** 18;
        require(msg.value == usdtAmount, "Invalid amount of usdt");
        token.transfer(msg.sender, _amount);
        soldTokens += _amount;
    }

    /*
        @des buy the tokens with usdt
        @param _amount amount of tokens to buy

     */
    function buyWithUsdt(uint256 _amount) public {
        require(_amount >= minTokens, "Amount is less than minimum tokens");
        require(_amount <= maxTokens, "Amount is more than maximum tokens");
        require(soldTokens + _amount <= totalTokens, "Not enough tokens left");
        uint256 price = getTokenPriceInUsdt();
        uint256 usdtAmount = (_amount * price) / 10 ** 18;
        usdt.transferFrom(msg.sender, address(this), usdtAmount);
        token.transfer(msg.sender, _amount);
        soldTokens += _amount;
    }

    /* setter functions */
    /*
        @des set the token address
        @param _token address of the token

     */

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    /*
        @des set the usdt address
        @param _usdt address of the usdt

     */

    function setUsdt(IERC20 _usdt) public onlyOwner {
        usdt = _usdt;
    }

    /*
        @des set all stages dates
        @param _stage1 , _stage2 , _stage3 , _stage4 , _stage5 , _stage6 dates of all stages

     */

    function setStages(
        uint256 _stage1,
        uint256 _stage2,
        uint256 _stage3,
        uint256 _stage4,
        uint256 _stage5,
        uint256 _stage6
    ) public onlyOwner {
        stage1 = _stage1;
        stage2 = _stage2;
        stage3 = _stage3;
        stage4 = _stage4;
        stage5 = _stage5;
        stage6 = _stage6;
    }

    /*
        @des set all stages prices
        @param _price1 , _price2 , _price3 , _price4 , _price5 , _price6 prices of all stages

     */
    function setPrices(
        uint256 _price1,
        uint256 _price2,
        uint256 _price3,
        uint256 _price4,
        uint256 _price5,
        uint256 _price6
    ) public onlyOwner {
        price1 = _price1;
        price2 = _price2;
        price3 = _price3;
        price4 = _price4;
        price5 = _price5;
        price6 = _price6;
    }

    /*
        @des set the total tokens to be sold
        @param _totalTokens total tokens to be sold

     */
    function setTotalTokens(uint256 _totalTokens) public onlyOwner {
        totalTokens = _totalTokens;
    }

    /*
        @des set the minimum and maximum tokens to be sold in each transaction
        @param _minTokens , _maxTokens minimum and maximum tokens to be sold in each transaction

     */
    function setMinMaxTokens(
        uint256 _minTokens,
        uint256 _maxTokens
    ) public onlyOwner {
        minTokens = _minTokens;
        maxTokens = _maxTokens;
    }

    /* getter functions */

    /*
        @des get the stage
        @return the stage of the presale

     */

    function getStage() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime <= stage1) {
            return 1;
        } else if (currentTime <= stage2) {
            return 2;
        } else if (currentTime <= stage3) {
            return 3;
        } else if (currentTime <= stage4) {
            return 4;
        } else if (currentTime <= stage5) {
            return 5;
        } else {
            return 6;
        }
    }

    /*
        @des get the price of the token
        @return the price of the token

     */

    function getPrice() public view returns (uint256) {
        uint256 stage = getStage();
        if (stage == 1) {
            return price1;
        } else if (stage == 2) {
            return price2;
        } else if (stage == 3) {
            return price3;
        } else if (stage == 4) {
            return price4;
        } else if (stage == 5) {
            return price5;
        } else {
            return price6;
        }
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    /*
        @des get the token price in usdt
        @return the price of the token in usdt

     */
    function getTokenPriceInUsdt() public view returns (uint256) {
        uint256 price = getPrice();
        uint usdtPrice = uint(getChainlinkDataFeedLatestAnswer());
        return (price * usdtPrice) / 10 ** 8;
    }
}
