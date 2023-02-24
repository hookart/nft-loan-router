pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/Flashloan.sol";
import "../src/external/nftfi/INFTFiDirect.sol";
import "../src/external/nftfi/INFTFIHub.sol";
import "../src/external/nftfi/INFTFIDirectLoanCoordinator.sol";
import "../src/external/reservoir/IReservoirRouterV6.sol";

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

    // set `block.number` of a fork
    function testCanMintBorrowerToken() public {
        // checks this transaction is successful... https://etherscan.io/tx/0x28659c5ea6cbb0f79e98c1ff95307fa91dfc7710281d9f45ecacb54cd06c44ae
        vm.startPrank(0x20794EF7693441799a3f38FCC22a12b3E04b9572);
        ERC721(address(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270)).setApprovalForAll(address(0x00000000006c3852cbEf3e08E8dF289169EdE581), true);
        vm.stopPrank();
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

        // we know the loan id because i looked it up on chain
        nftfi.mintObligationReceipt(26524);

        bytes memory reserviorOrder = vm.parseBytes(
            /// hack -- modify the from address of the safe transfer from
            // "0xb88d4fde000000000000000000000000057F068D066A27A1c94f3b0533cB4455f6a7551000000000000000000000000020794ef7693441799a3f38fcc22a12b3e04b9572000000000000000000000000000000000000000000000000000000000cd0a72f00000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000924760f2a0b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000020794ef7693441799a3f38fcc22a12b3e04b95720000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008246baab5f700000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000005c00000000000000000000000008252df1d8b29057d1afe3062bf5a64d503152bc80000000000000000000000008252df1d8b29057d1afe3062bf5a64d503152bc80000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000046000000000000000000000000000000000000000000000000000000000000004e00000000000000000000000001d59d9fc68fa6bafdf03201939d6e8f10f7c75a0000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000063f77add0000000000000000000000000000000000000000000000000000000063f8cc570000000000000000000000000000000000000000000000000000000000000000360c6ebe00000000000000000000000000000000000000009de62cd7965ad34b0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d05ffef2767d8000000000000000000000000000000000000000000000000000d05ffef2767d800000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000a7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270614cbeac39a4acf88c1c57596a22ebc027c791315000e7359ffbbeab51df5a95000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000001d59d9fc68fa6bafdf03201939d6e8f10f7c75a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010ab85092833000000000000000000000000000000000000000000000000000010ab850928330000000000000000000000000006c093fe8bc59e1e0cae2ec10f0b717d3d182056b00000000000000000000000000000000000000000000000000000000000000415f40ae1bbba06de1d0d54bb214897ef597d3b54defb06e5a7876ffb041c175586223a29f92be63fea79337369dae494ced1a6f61a73876d767786d185d9a8e281b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cd0a72f00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000af681ada6515b8fe2a7ade09738b87412ca7a2e54a8cc6493362366db26988997fe3984bdc65a1dfbada8bf5c1d27cafeb1fa3b4e6783f0cb04172b7166bfa0b933c31ab1fa7bc447748aa9689d622303b12781070f8b583d53fc3d076bc675f11994e047ee3c94e5b96962756947d54dee1a5c509cebdf58bfe0af3408f051c9bb6c6310f2282f4dc16bd760b12dc792625b8edf7e021e89cf9735de3b82016f6d415b2de9ac5e93286d2232f99b6bf470c6eda70f3724230bb153e33762a24e5258b57e2d086a6c5f368b926f650da720fa98a465c7a6c71f730b9682720d3bf305ea25ebd7e944f6e538a5d849f55a99e50479caf033eafa27b51c2a1f36efd484c07651428fe4889b5402a541c45940f1edfc6346f0a4ed7932b61072d7e7e7f461a8cd2acf73e2ec9f2ed5f2b9d2ac846f959499d948e19f16075c835a8a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            // "0xb88d4fde000000000000000000000000057f068d066a27a1c94f3b0533cb4455f6a7551000000000000000000000000020794ef7693441799a3f38fcc22a12b3e04b9572000000000000000000000000000000000000000000000000000000000cd0a72f00000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000924760f2a0b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000020794ef7693441799a3f38fcc22a12b3e04b95720000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008246baab5f700000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000005c0000000000000000000000000057f068d066a27a1c94f3b0533cb4455f6a75510000000000000000000000000057f068d066a27a1c94f3b0533cb4455f6a755100000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000046000000000000000000000000000000000000000000000000000000000000004e00000000000000000000000001d59d9fc68fa6bafdf03201939d6e8f10f7c75a0000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000063f77add0000000000000000000000000000000000000000000000000000000063f8cc570000000000000000000000000000000000000000000000000000000000000000360c6ebe00000000000000000000000000000000000000009de62cd7965ad34b0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d05ffef2767d8000000000000000000000000000000000000000000000000000d05ffef2767d800000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000a7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270614cbeac39a4acf88c1c57596a22ebc027c791315000e7359ffbbeab51df5a95000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000001d59d9fc68fa6bafdf03201939d6e8f10f7c75a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010ab85092833000000000000000000000000000000000000000000000000000010ab850928330000000000000000000000000006c093fe8bc59e1e0cae2ec10f0b717d3d182056b00000000000000000000000000000000000000000000000000000000000000415f40ae1bbba06de1d0d54bb214897ef597d3b54defb06e5a7876ffb041c175586223a29f92be63fea79337369dae494ced1a6f61a73876d767786d185d9a8e281b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cd0a72f00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000af681ada6515b8fe2a7ade09738b87412ca7a2e54a8cc6493362366db26988997fe3984bdc65a1dfbada8bf5c1d27cafeb1fa3b4e6783f0cb04172b7166bfa0b933c31ab1fa7bc447748aa9689d622303b12781070f8b583d53fc3d076bc675f11994e047ee3c94e5b96962756947d54dee1a5c509cebdf58bfe0af3408f051c9bb6c6310f2282f4dc16bd760b12dc792625b8edf7e021e89cf9735de3b82016f6d415b2de9ac5e93286d2232f99b6bf470c6eda70f3724230bb153e33762a24e5258b57e2d086a6c5f368b926f650da720fa98a465c7a6c71f730b9682720d3bf305ea25ebd7e944f6e538a5d849f55a99e50479caf033eafa27b51c2a1f36efd484c07651428fe4889b5402a541c45940f1edfc6346f0a4ed7932b61072d7e7e7f461a8cd2acf73e2ec9f2ed5f2b9d2ac846f959499d948e19f16075c835a8a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            "0x6baab5f700000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000005c0000000000000000000000000057f068d066a27a1c94f3b0533cb4455f6a75510000000000000000000000000057f068d066a27a1c94f3b0533cb4455f6a755100000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000046000000000000000000000000000000000000000000000000000000000000004e00000000000000000000000001d59d9fc68fa6bafdf03201939d6e8f10f7c75a0000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000063f77add0000000000000000000000000000000000000000000000000000000063f8cc570000000000000000000000000000000000000000000000000000000000000000360c6ebe00000000000000000000000000000000000000009de62cd7965ad34b0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d05ffef2767d8000000000000000000000000000000000000000000000000000d05ffef2767d800000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000a7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270614cbeac39a4acf88c1c57596a22ebc027c791315000e7359ffbbeab51df5a95000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000001d59d9fc68fa6bafdf03201939d6e8f10f7c75a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010ab85092833000000000000000000000000000000000000000000000000000010ab850928330000000000000000000000000006c093fe8bc59e1e0cae2ec10f0b717d3d182056b00000000000000000000000000000000000000000000000000000000000000415f40ae1bbba06de1d0d54bb214897ef597d3b54defb06e5a7876ffb041c175586223a29f92be63fea79337369dae494ced1a6f61a73876d767786d185d9a8e281b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cd0a72f00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000af681ada6515b8fe2a7ade09738b87412ca7a2e54a8cc6493362366db26988997fe3984bdc65a1dfbada8bf5c1d27cafeb1fa3b4e6783f0cb04172b7166bfa0b933c31ab1fa7bc447748aa9689d622303b12781070f8b583d53fc3d076bc675f11994e047ee3c94e5b96962756947d54dee1a5c509cebdf58bfe0af3408f051c9bb6c6310f2282f4dc16bd760b12dc792625b8edf7e021e89cf9735de3b82016f6d415b2de9ac5e93286d2232f99b6bf470c6eda70f3724230bb153e33762a24e5258b57e2d086a6c5f368b926f650da720fa98a465c7a6c71f730b9682720d3bf305ea25ebd7e944f6e538a5d849f55a99e50479caf033eafa27b51c2a1f36efd484c07651428fe4889b5402a541c45940f1edfc6346f0a4ed7932b61072d7e7e7f461a8cd2acf73e2ec9f2ed5f2b9d2ac846f959499d948e19f16075c835a8a0000000000000000000000000000000000000000000000000000000000000000"
        );

        // nftfi.payBackLoan(26524);

        address module = address(0x20794EF7693441799a3f38FCC22a12b3E04b9572);
        // address reservior = address(0x178A86D36D89c7FDeBeA90b739605da7B131ff6A);
        // ReservoirV6 router = ReservoirV6(reservior);
        ReservoirV6.ExecutionInfo[]
            memory executionInfo = new ReservoirV6.ExecutionInfo[](1);
        executionInfo[0] = ReservoirV6.ExecutionInfo({
            // module: address(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270),
            module: module,
            data: reserviorOrder,
            value: 0
        });

        // router.execute(executionInfo);

        Flashloan fl = new Flashloan();
        ERC721(address(0xe73ECe5988FfF33a012CEA8BB6Fd5B27679fC481))
            .setApprovalForAll(address(fl), true);
        fl.repayAndSell(
            26524,
            executionInfo,
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        );

        // after doing the transaction, now we can try to mint the obligation note
    }
}
