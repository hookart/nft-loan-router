// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./external/reservoir/IReservoirRouterV6.sol";
import "./external/euler-xyz/Interfaces.sol";
import "./external/nftfi/INFTFiDirect.sol";
import "./external/nftfi/INFTFIDirectLoanCoordinator.sol";
import "./external/nftfi/INFTFIHub.sol";
import "../lib/solmate/src/tokens/ERC721.sol";
import "./Constants.sol";

contract RepayAndSellNftFi is Constants {
    INftFiDirect nftFi;
    INFTFIDirectLoanCoordinator coord;
    ReservoirV6 reservoir;
    IERC3156FlashLender lender;

    constructor() {
        nftFi = INftFiDirect(NFTFI_DIRECT_LOAN_COORDINATOR_ADDR);
        coord = INFTFIDirectLoanCoordinator(
            INftfiHub(NFTFI_DIRECT_LOAN_COORDINATOR_ADDR).getContract(
                nftFi.LOAN_COORDINATOR()
            )
        );
        reservoir = ReservoirV6(RESERVOIR_V6_ADDR);
        lender = IERC3156FlashLender(EULER_ADDR);
    }

    function repayAndSell(
        uint32 loanId,
        ReservoirV6.ExecutionInfo[] calldata saleExecutionInfos,
        address token
    ) public {
        // also make sure that our proxy contract is allowed to use token with NFTFi

        // (1) verify that the owner owns loan number, that it is not already repaid or liquidate
        require(
            nftFi.loanRepaidOrLiquidated(loanId) == false,
            "loan already repaid or liquidated"
        );

        INFTFIDirectLoanCoordinator.Loan memory loanData = coord.getLoanData(
            loanId
        );
        ERC721 obligation = ERC721(coord.obligationReceiptToken());
        require(
            obligation.ownerOf(loanData.smartNftId) == msg.sender,
            "only the owner of the loan can repay and sell"
        );

        // (2) verify that this contract address(this) is approved to move the borrower note
        obligation.isApprovedForAll(msg.sender, address(this));

        // (3) flashloan some money to do the repayment (figure out how much from the loan contract?)
        uint256 payoffAmount = nftFi.getPayoffAmount(loanId);
        IERC3156FlashBorrower receiver = IERC3156FlashBorrower(address(this));
        bytes memory flashLoanData = abi.encode(loanId, saleExecutionInfos);

        lender.flashLoan(receiver, token, payoffAmount, flashLoanData);

        // (4) if flashloan repayment is successful, then return the net proceeds to the caller
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function repayLoan(uint32 loanId) internal {
        nftFi.payBackLoan(loanId);
    }

    // TODO: add a function to sell the collateral to the reservoir api using the passed order
    function sellCollateral(
        ReservoirV6.ExecutionInfo[] calldata saleExecutionInfos
    ) internal {
        // verify that the order is valid to sell the loan to
        // verify that the order is worth more than the repayment amount.
        reservoir.execute(saleExecutionInfos);
    }
}
