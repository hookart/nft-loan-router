// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./external/reservoir/IReservoirRouterV6.sol";
import "./external/euler-xyz/Interfaces.sol";
import "./external/nftfi/INFTFiDirect.sol";
import "./external/nftfi/INFTFIDirectLoanCoordinator.sol";
import "./external/nftfi/INFTFIHub.sol";
import "solmate/tokens/ERC721.sol";
import "./Constants.sol";
import "./Flashloan.sol";

contract RepayAndSell is Constants, Flashloan {
    INftFiDirect nftFi;
    INFTFIDirectLoanCoordinator coord;
    ReservoirV6 reservoir;

    constructor(address flashLoanLender) Flashloan(flashLoanLender) {
        nftFi = INftFiDirect(NFTFI_DIRECT_LOAN_COORDINATOR_ADDR);
        coord = INFTFIDirectLoanCoordinator(
            INftfiHub(nftFi.hub()).getContract(nftFi.LOAN_COORDINATOR())
        );
        reservoir = ReservoirV6(RESERVOIR_V6_ADDR);
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
        require(
            obligation.isApprovedForAll(msg.sender, address(this)),
            "we must be approved to move oblig note"
        );
        obligation.transferFrom(msg.sender, address(this), loanData.smartNftId);

        // (3) flashloan some money to do the repayment (figure out how much from the loan contract?)
        uint256 payoffAmount = nftFi.getPayoffAmount(loanId);
        bytes memory flashLoanData = abi.encode(
            loanId,
            address(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270),
            saleExecutionInfos
        );

        flashLoan(token, payoffAmount, flashLoanData);

        // (4) if flashloan repayment is successful, then return the net proceeds to the caller
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function internalExecuteRepayAndSell(
        uint32 tokenId,
        address tokenAddress,
        ReservoirV6.ExecutionInfo[] memory saleExecutionInfos
    ) internal override {
        // (1) repay the original loan
        IERC20(_token).approve(
            address(0x8252Df1d8b29057d1Afe3062bf5a64D503152BC8),
            type(uint256).max
        );

        ERC721(address(tokenAddress)).setApprovalForAll(
            address(reservoir),
            true
        );

        repayLoan(tokenId);

        // (2) sell the collateral to the reservoir api using the passed order

        // give reservior access to this token.
        ERC721(address(tokenAddress)).setApprovalForAll(
            address(reservoir),
            true
        );
        reservoir.execute(saleExecutionInfos);
    }

    function repayLoan(uint32 loanId) internal {
        nftFi.payBackLoan(loanId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
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
