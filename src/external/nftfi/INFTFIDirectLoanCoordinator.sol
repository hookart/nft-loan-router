// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

/**
 * @title IDirectLoanCoordinator
 * @author NFTfi
 * @dev DirectLoanCoordinator interface.
 */
interface INFTFIDirectLoanCoordinator {
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }

    /**
     * @notice This struct contains data related to a loan
     *
     * @param smartNftId - The id of both the promissory note and obligation receipt.
     * @param status - The status in which the loan currently is.
     * @param loanContract - Address of the LoanType contract that created the loan.
     */
    struct Loan {
        address loanContract;
        uint64 smartNftId;
        StatusType status;
    }

    function mintObligationReceipt(uint32 _loanId, address _borrower) external;

    function promissoryNoteToken() external view returns (address);

    function obligationReceiptToken() external view returns (address);

    function getLoanData(uint32 _loanId) external view returns (Loan memory);

    function registerLoan(
        address _lender,
        bytes32 _loanType,
        uint256 loanId
    ) external returns (uint32);

    function isValidLoanId(uint32 _loanId, address _loanContract)
        external
        view
        returns (bool);
}
