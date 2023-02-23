pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/external/nftfi/INFTFiDirect.sol";
import "../src/external/nftfi/INFTFIHub.sol";
import "../src/external/nftfi/INFTFIDirectLoanCoordinator.sol";

contract ForkTest is Test {
    // the identifiers of the forks
    uint256 mainnetFork;
    address nftfiuser = 0xfd2F20EDc68Ce46101F3DB74D12E131CaEE65CA2;
    INftFiDirect nftfi =
        INftFiDirect(address(0x8252Df1d8b29057d1Afe3062bf5a64D503152BC8));

    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need
    //inside your .env file e.g:
    //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    // create two _different_ forks during setup
    function setUp() public {
        mainnetFork = vm.createSelectFork(MAINNET_RPC_URL);
        vm.rollFork(16693616);
    }

    // 0	_offer.loanPrincipalAmount	uint256	12000000000000000000
    // 0	_offer.maximumRepaymentAmount	uint256	12088767123287670000
    // 0	_offer.nftCollateralId	uint256	215000879
    // 0	_offer.nftCollateralContract	address	0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270
    // 0	_offer.loanDuration	uint32	2592000
    // 0	_offer.loanAdminFeeInBasisPoints	uint16	500
    // 0	_offer.loanERC20Denomination	address	0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // 0	_offer.referrer	address	0x0000000000000000000000000000000000000000
    // 1	_signature.nonce	uint256	67229454090402225709441078451587605363272439730431727412225279892058535254547
    // 1	_signature.expiry	uint256	1677229036
    // 1	_signature.signer	address	0x1797b4235473fbE0e7e44322F01C1B5618EBda41
    // 1	_signature.signature	bytes	0x692932bac591810d46042cf9f8138418d44906aea8fee91d180e49f98cb22f424b27aefbe94d0060054c35a850e666a5908f40b63ca9a1db13398a9e720db3ba1b
    // 2	_borrowerSettings.revenueSharePartner	address	0x0000000000000000000000000000000000000000
    // 2	_borrowerSettings.referralFeeInBasisPoints	uint16	0
    // set `block.number` of a fork
    function testCanMintBorrowerToken() public {
        // checks this transaction is successful... https://etherscan.io/tx/0x28659c5ea6cbb0f79e98c1ff95307fa91dfc7710281d9f45ecacb54cd06c44ae
        vm.startPrank(nftfiuser);
        nftfi.acceptOffer(
            LoanData.Offer({
                loanPrincipalAmount: 12000000000000000000,
                maximumRepaymentAmount: 12088767123287670000,
                nftCollateralContract: address(
                    0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270
                ),
                nftCollateralId: 215000879,
                loanDuration: 2592000,
                loanAdminFeeInBasisPoints: 500,
                referrer: address(0),
                loanERC20Denomination: address(
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
                )
            }),
            LoanData.Signature({
                signer: address(0x1797b4235473fbE0e7e44322F01C1B5618EBda41),
                nonce: 67229454090402225709441078451587605363272439730431727412225279892058535254547,
                expiry: 1677229036,
                signature: vm.parseBytes(
                    "0x692932bac591810d46042cf9f8138418d44906aea8fee91d180e49f98cb22f424b27aefbe94d0060054c35a850e666a5908f40b63ca9a1db13398a9e720db3ba1b"
                )
            }),
            LoanData.BorrowerSettings({
                revenueSharePartner: address(0),
                referralFeeInBasisPoints: 0
            })
        );

        INFTFIDirectLoanCoordinator coord = INFTFIDirectLoanCoordinator(
            INftfiHub(nftfi.hub()).getContract(nftfi.LOAN_COORDINATOR())
        );

        console.log(address(coord));

        nftfi.mintObligationReceipt(26524);
        // after doing the transaction, now we can try to mint the obligation note
    }
}
