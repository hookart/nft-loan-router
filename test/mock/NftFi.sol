// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.5;

import "../../src/external/nftfi/INftFiDirect.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC20.sol";

contract NFTFIERC721 is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        "nope";
    }

    function burn(uint256 id) public {
        _burn(id);
    }
}

contract NftFiMock is INftFiDirect {
    NFTFIERC721 private promNote;
    NFTFIERC721 private obligationReciept;
    uint256 private loanId = 0;

    mapping(uint256 => LoanData.LoanTerms) private loans;

    constructor() {
        promNote = new NFTFIERC721("prom note", "PROM");
        obligationReciept = new NFTFIERC721("obligationReciept", "OBLIG");
    }

    function getPayoffAmount(uint32 _loanId)
        external
        view
        override
        returns (uint256)
    {
        return 0;
    }

    function loanRepaidOrLiquidated(uint32)
        external
        view
        override
        returns (bool)
    {
        return false;
    }

    /**
     * @dev Creates a `LoanTerms` struct using data sent as the lender's `_offer` on `acceptOffer`.
     * This is needed in order to avoid stack too deep issues.
     * Since this is a Fixed loan type loanInterestRateForDurationInBasisPoints is ignored.
     */
    function _setupLoanTerms(LoanData.Offer memory _offer, address _nftWrapper)
        internal
        view
        returns (LoanData.LoanTerms memory)
    {
        return
            LoanData.LoanTerms({
                loanERC20Denomination: _offer.loanERC20Denomination,
                loanPrincipalAmount: _offer.loanPrincipalAmount,
                maximumRepaymentAmount: _offer.maximumRepaymentAmount,
                nftCollateralContract: _offer.nftCollateralContract,
                nftCollateralWrapper: _nftWrapper,
                nftCollateralId: _offer.nftCollateralId,
                loanStartTime: uint64(block.timestamp),
                loanDuration: _offer.loanDuration,
                loanInterestRateForDurationInBasisPoints: uint16(0),
                loanAdminFeeInBasisPoints: _offer.loanAdminFeeInBasisPoints,
                borrower: msg.sender
            });
    }

    function _getPartiesAndData(uint32 _loanId)
        internal
        view
        returns (
            address borrower,
            address lender,
            LoanData.LoanTerms memory loan
        )
    {
        // Fetch loan details from storage, but store them in memory for the sake of saving gas.
        loan = loans[_loanId];
        if (loan.borrower != address(0)) {
            borrower = loan.borrower;
        } else {
            // Fetch current owner of loan obligation note.
            borrower = ERC721(obligationReciept).ownerOf(_loanId);
        }
        lender = ERC721(promNote).ownerOf(_loanId);
    }

    /**
     * @notice This function is called by the borrower when accepting a lender's offer to begin a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _signature - The components of the lender's signature.
     * @param _borrowerSettings - Some extra parameters that the borrower needs to set when accepting an offer.
     */
    function acceptOffer(
        LoanData.Offer memory _offer,
        LoanData.Signature memory _signature,
        LoanData.BorrowerSettings memory _borrowerSettings
    ) external override {
        loanId++;
        loans[loanId] = _setupLoanTerms(_offer, _offer.nftCollateralContract);
        ERC721(_offer.nftCollateralContract).transferFrom(
            msg.sender,
            address(this),
            _offer.nftCollateralId
        );
        ERC20(_offer.loanERC20Denomination).transferFrom(
            _signature.signer,
            msg.sender,
            _offer.loanPrincipalAmount
        );
        promNote.mint(_signature.signer, loanId);
        obligationReciept.mint(msg.sender, loanId);
    }

    /**
     * @notice This function is called by a anyone to repay a loan. It can be called at any time after the loan has
     * begun and before loan expiry.. The caller will pay a pro-rata portion of their interest if the loan is paid off
     * early and the loan is pro-rated type, but the complete repayment amount if it is fixed type.
     * The the borrower (current owner of the obligation note) will get the collaterl NFT back.
     *
     * This function is purposefully not pausable in order to prevent an attack where the contract admin's pause the
     * contract and hold hostage the NFT's that are still within it.
     *
     * @param _loanId  A unique identifier for this particular loan, sourced from the Loan Coordinator.
     */
    function payBackLoan(uint32 _loanId) external override {
        (
            address borrower,
            address lender,
            LoanData.LoanTerms memory loan
        ) = _getPartiesAndData(_loanId);
        require(
            block.timestamp < loan.loanStartTime + loan.loanDuration,
            "Loan has already expired"
        );
        require(loan.loanPrincipalAmount > 0, "Loan has already been repaid");
        uint256 repaymentAmount = loan.maximumRepaymentAmount;

        ERC20(loan.loanERC20Denomination).transferFrom(
            borrower,
            lender,
            repaymentAmount
        );
        ERC721(loan.nftCollateralContract).transferFrom(
            address(this),
            borrower,
            loan.nftCollateralId
        );
        promNote.burn(loanId);
        obligationReciept.burn(loanId);
    }
}
