// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.5;

import "../../src/external/nftfi/INftFiDirect.sol";
import "solmate/tokens/ERC721.sol";

contract NftFiMock is INftFiDirect {
    ERC721 private promNote;
    ERC721 private obligationReciept;

    constructor() {
        promNote = new ERC721("prom note", "PROM");
        obligationReciept = new ERC721("obligationReciept", "OBLIG");
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
    ) external {
        _offer.loanId;
        ERC721(_offer.nftCollateralContract).transferFrom(
            msg.sender,
            address(this),
            _offer.nftCollateralId
        );
        ERC20(_offer.loanERC20Denomination).transferFrom(
            _signature.signer,
            msg.sender,
            _offer.loanPrincipalAmount,
        );
        promNote.mint(_signature.signer, 1);
        obligationReciept.mint(mgs.sender, 1);
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
    function payBackLoan(uint32 _loanId) external;
}
