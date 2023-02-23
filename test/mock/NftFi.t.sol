pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/tokens/WETH.sol";
import "./NftFi.sol";

contract NftFiMockTest is Test {
    NftFiMock private mock;
    NFTFIERC721 private collateralNft;
    WETH private weth;

    function setUp() public {
        mock = new NftFiMock();
        collateralNft = new NFTFIERC721("collateral", "COLLATERAL");
        weth = new WETH();
    }

    function testPromNoteIsErc721() public {
        DirectLoanCoordinator coord = DirectLoanCoordinator(
            INftfiHub(mock.hub()).getContract(mock.LOAN_COORDINATOR())
        );
        assertTrue(
            ERC721(coord.promissoryNoteToken()).supportsInterface(0x01ffc9a7)
        );
    }

    function testObligReciptIsErc721() public {
        DirectLoanCoordinator coord = DirectLoanCoordinator(
            INftfiHub(mock.hub()).getContract(mock.LOAN_COORDINATOR())
        );
        assertTrue(
            ERC721(coord.obligationReceiptToken()).supportsInterface(0x01ffc9a7)
        );
    }

    function testAcceptOffer() public {
        address lender = address(0x1e2d);
        vm.deal(lender, 100 ether);
        address borrower = address(0xb3);
        vm.deal(borrower, 10 ether);
        collateralNft.mint(borrower, 1);

        vm.startPrank(borrower);
        collateralNft.setApprovalForAll(address(mock), true);
        weth.deposit{value: 10 ether}();
        vm.stopPrank();

        vm.startPrank(lender);
        weth.deposit{value: 10 ether}();
        weth.approve(address(mock), type(uint256).max);
        vm.stopPrank();

        vm.prank(borrower);
        mock.acceptOffer(
            LoanData.Offer({
                loanPrincipalAmount: 1 ether,
                maximumRepaymentAmount: 1.1 ether,
                nftCollateralContract: address(collateralNft),
                nftCollateralId: 1,
                loanDuration: 100,
                loanAdminFeeInBasisPoints: 0,
                referrer: address(0),
                loanERC20Denomination: address(weth)
            }),
            LoanData.Signature({
                signer: lender,
                nonce: 0,
                expiry: 0,
                signature: bytes("0")
            }),
            LoanData.BorrowerSettings({
                revenueSharePartner: address(0),
                referralFeeInBasisPoints: 0
            })
        );

        assertEq(weth.balanceOf(lender), 9 ether);
        assertEq(weth.balanceOf(borrower), 11 ether);
        assertEq(collateralNft.ownerOf(1), address(mock));
    }
}
