// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.5;

import "../../src/external/nftfi/INftFiDirect.sol";
import "../../src/external/nftfi/INftFiHub.sol";
import "../../src/external/nftfi/INFTFIDirectLoanCoordinator.sol";
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

contract NftfiHub is INftfiHub {
    /* ******* */
    /* STORAGE */
    /* ******* */

    mapping(bytes32 => address) private contracts;

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice Set or update the contract address for the given key.
     * @param _contractKey - New or existing contract key.
     * @param _contractAddress - The associated contract address.
     */
    function setContract(string calldata _contractKey, address _contractAddress)
        external
        override
    {
        _setContract(_contractKey, _contractAddress);
    }

    /**
     * @notice This function can be called by anyone to lookup the contract address associated with the key.
     * @param  _contractKey - The index to the contract address.
     */
    function getContract(bytes32 _contractKey)
        external
        view
        override
        returns (address)
    {
        return contracts[_contractKey];
    }

    function getIdFromStringKey(string memory _key)
        internal
        pure
        returns (bytes32 id)
    {
        require(bytes(_key).length <= 32, "invalid key");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := mload(add(_key, 32))
        }
    }

    /**
     * @notice Set or update the contract address for the given key.
     * @param _contractKey - New or existing contract key.
     * @param _contractAddress - The associated contract address.
     */
    function _setContract(string memory _contractKey, address _contractAddress)
        internal
    {
        contracts[getIdFromStringKey(_contractKey)] = _contractAddress;
    }
}

contract DirectLoanCoordinator is INFTFIDirectLoanCoordinator {
    /**
     * @dev reverse mapping of loanTypes - for each contract address, records the associated loan type
     */
    mapping(address => bytes32) private contractTypes;

    bool private _initialized = false;

    mapping(uint32 => Loan) private loans;

    address public override promissoryNoteToken;
    address public override obligationReceiptToken;

    modifier onlyInitialized() {
        require(_initialized, "not initialized");

        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    function initialize(
        address _promissoryNoteToken,
        address _obligationReceiptToken
    ) external {
        require(
            _promissoryNoteToken != address(0),
            "promissoryNoteToken is zero"
        );
        require(
            _obligationReceiptToken != address(0),
            "obligationReceiptToken is zero"
        );

        _initialized = true;
        promissoryNoteToken = _promissoryNoteToken;
        obligationReceiptToken = _obligationReceiptToken;
    }

    function mintObligationReceipt(uint32 _loanId, address _borrower)
        external
        override
        onlyInitialized
    {
        // not implemented
        NFTFIERC721(obligationReceiptToken).mint(msg.sender, _loanId);
    }

    /**
     * @dev Returns loan's data for a given id.
     *
     * @param _loanId - Id of the loan
     */
    function getLoanData(uint32 _loanId)
        external
        view
        override
        returns (Loan memory)
    {
        return loans[_loanId];
    }

    function registerLoan(
        address _lender,
        bytes32 _loanType,
        uint256 loanId
    ) external override returns (uint32) {
        return uint32(loanId);
    }

    /**
     * @dev checks if the given id is valid for the given loan contract address
     * @param _loanId - Id of the loan
     * @param _loanContract - address og the loan contract
     */
    function isValidLoanId(uint32 _loanId, address _loanContract)
        external
        view
        override
        returns (bool validity)
    {
        validity = loans[_loanId].loanContract == _loanContract;
    }
}

contract NftFiMock is INftFiDirect {
    NFTFIERC721 private promNote;
    NFTFIERC721 private obligationReciept;
    uint256 private loanId = 0;

    bytes32 public immutable override LOAN_COORDINATOR;
    INftfiHub public immutable hub;
    // hub.getContract(LOAN_COORDINATOR);

    mapping(uint256 => LoanData.LoanTerms) private loans;

    constructor() {
        promNote = new NFTFIERC721("prom note", "PROM");
        obligationReciept = new NFTFIERC721("obligationReciept", "OBLIG");
        DirectLoanCoordinator coordinator = new DirectLoanCoordinator();
        coordinator.initialize(address(promNote), address(obligationReciept));
        LOAN_COORDINATOR = getIdFromStringKey("DIRECT_LOAN_COORDINATOR");
        hub = new NftfiHub();
        hub.setContract("DIRECT_LOAN_COORDINATOR", address(coordinator));
    }

    function getIdFromStringKey(string memory _key)
        internal
        pure
        returns (bytes32 id)
    {
        require(bytes(_key).length <= 32, "invalid key");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := mload(add(_key, 32))
        }
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

        INFTFIDirectLoanCoordinator loanCoordinator = INFTFIDirectLoanCoordinator(
                hub.getContract(LOAN_COORDINATOR)
            );
        loanCoordinator.registerLoan(
            _signature.signer,
            getIdFromStringKey("no"),
            loanId
        );
        promNote.mint(_signature.signer, loanId);
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
