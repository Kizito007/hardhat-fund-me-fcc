//  Get Funds from users
//  Withdraw Funds
//  Set minimum value in USD

//  SPDX-License-Identifier: MIT
//  Pragma
pragma solidity ^0.8.8;
//  Imports
import "./PriceConverter.sol";
import "hardhat/console.sol";

//837,069 : before constant keyword
//817,527 : after constant keyword
//  Error Codes
error FundMe__NotOwner();

//  Interfaces, Libraries, Contract
//  NATSPEC Format below
/** @title A contract for crowd funding
 *  @author Kizito Nwaka
 *  @notice This contract is to demo a sample funding contract
 *  @dev    This implements price feeds as our library
 */

contract FundMe {
    //  Type Declarations
    using PriceConverter for uint256;

    //  State Variables
    AggregatorV3Interface private s_priceFeed;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    uint256 public constant MINIMUM_USD = 50 * 1e18; //   1 * 10 ** 18
    address private immutable i_owner;

    //  modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    //  immutable 21,508 gas
    //  non-immutable 23,644 gas
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     *  @notice Thifunction funds the contract
     *  @dev    This implements price feeds as our library
     */
    function fund() public payable {
        //  send min fund amount
        //  how do we send eth

        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        ); // 1 * 10 ^ 18
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        /* starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //  reset the array
        s_funders = new address[](0);
        //  withdraw funds : call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        console.log("Successfully Withdrawn");
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory
        /* starting index, ending index, step amount */

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //  reset the array
        s_funders = new address[](0);
        //  withdraw funds : call
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // View/Pure

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
