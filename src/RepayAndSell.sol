// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./external/reservoir/IReservoirRouterV6.sol";
import "./external/euler-xyz/Interfaces.sol";

contract RepayAndSellNftFi {
    // TODO: these are temporary values, change to actual addresses
    address internal constant WETH_ADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant EULER_ADDR =
        0x27182842E098f60e3D576794A5bFFb0777E025d3;

    // set the lender to the euler flashloan contract
    IERC3156FlashLender internal constant lender =
        IERC3156FlashLender(EULER_ADDR);

    function repayAndSell(
        uint256 loanNumber,
        ReservoirV6.ExecutionInfo[] calldata saleExecutionInfos
    ) public {
        // (1) verify that the owner owns loan number, that it is not already repaid or liquidate
        // (2) verify that this contract address(this) is approved to move the borrower note
        // (3) verify that the order is valid to sell the loan to
        // (3.5) verify that the order is worth more than the repayment amount.
        // (4) flashloan some money to do the repayment (figure out how much from the loan contract?)
        IERC3156FlashBorrower receiver = IERC3156FlashBorrower(address(this));
        address token = WETH_ADDR;
        uint256 amount = 0;
        bytes memory data = abi.encode(token, amount);
        lender.flashLoan(receiver, token, amount, data);

        // (5) repay the loan
        // when the flashloan is received, "onFlashLoan" is called, which calls another function to execute the logic
        // to repay the NFT loan, sell the collateral NFT, and repay the flashloan
        // (6) sell the collateral (now in this contract) to the reservoir api using the passed order
        // (7) repay the flash loan

        // (8) if flashloan repayment is successful, then return the net proceeds to the caller
    }
}
