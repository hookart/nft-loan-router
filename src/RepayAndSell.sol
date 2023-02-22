// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

contract RepayAndSellNftFi {
    function repayAndSell(uint256 loanNumber, order) public {
        // (1) verify that the owner owns loan number, that it is not already repaid or liquidate
        // (2) verify that this contract address(this) is approved to move the borrower note
        // (3) verify that the order is valid to sell the loan to
        // (3.5) verify that the order is worth more than the repayment amount.
        // (4) flashloan some money to do the repayment (figure out how much from the loan contract?)
        // (5) repay the loan
        // (6) sell the collateral (now in this contract) to the reservior api using the passed order
        // (7) repay the flash loan
        // (8) return the net proceeds to the caller
    }
}
