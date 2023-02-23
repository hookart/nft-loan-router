// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./external/reservoir/IReservoirRouterV6.sol";
import "./external/euler-xyz/Interfaces.sol";
import "./external/nftfi/INFTFiDirect.sol";
import "./external/nftfi/INFTFIDirectLoanCoordinator.sol";
import "./external/nftfi/INFTFIHub.sol";
import "solmate/tokens/ERC721.sol";

contract RepayAndSellNftFi {
    // TODO: these are temporary values, change to actual addresses
    address internal constant WETH_ADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant EULER_ADDR =
        0x27182842E098f60e3D576794A5bFFb0777E025d3;

    // set the lender to the euler flashloan contract
    IERC3156FlashLender internal constant lender =
        IERC3156FlashLender(EULER_ADDR);

    INftFiDirect nftFi =
        INftFiDirect(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    INFTFIDirectLoanCoordinator coord =
        INFTFIDirectLoanCoordinator(
            INftfiHub(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).getContract(
                nftFi.LOAN_COORDINATOR()
            )
        );

    function repayAndSell(
        uint256 loanNumber,
        ReservoirV6.ExecutionInfo[] calldata saleExecutionInfos
    ) public {
        // (1) verify that the owner owns loan number, that it is not already repaid or liquidate
        require(
            nftFi.loanRepaidOrLiquidated(loanNumber) == false,
            "loan already repaid or liquidated"
        );

        loanData = coord.getLoanData(loanNumber);
        address obligationReceiptOwner = ERC721(coord.obligationReceiptToken())
            .ownerOf();
        require(
            obligationReceiptOwner == msg.sender,
            "only the owner of the loan can repay and sell"
        );

        // (2) verify that this contract address(this) is approved to move the borrower note
        // (3) verify that the order is valid to sell the loan to
        // (3.5) verify that the order is worth more than the repayment amount.
        uint256 payoffAmount = nftFi.getPayoffAmount(loanNumber);

        // (4) flashloan some money to do the repayment (figure out how much from the loan contract?)
        IERC3156FlashBorrower receiver = IERC3156FlashBorrower(address(this));
        address token = WETH_ADDR;
        bytes memory flashLoanData = abi.encode(loanNumber);
        lender.flashLoan(receiver, token, payoffAmount, flashLoanData);

        // (5) if flashloan repayment is successful, then return the net proceeds to the caller
    }

    // TODO: add a function to repay the original loan
    function repayLoan(uint256 loanNumber) internal {}

    // TODO: add a function to sell the collateral to the reservoir api using the passed order
    function sellCollateral(
        ReservoirV6.ExecutionInfo[] calldata saleExecutionInfos
    ) internal {}
}
