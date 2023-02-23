pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "solmate/tokens/ERC721.sol";
import "./NftFi.sol";

contract NftFiMockTest is Test {
    NftFiMock private mock;

    function setUp() public {
        mock = new NftFiMock();
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
}
