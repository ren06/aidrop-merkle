// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {DeployMerkleAirdrop} from "../../script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    MerkleAirdrop airdrop;
    BagelToken token;
    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32 private constant PROOF1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 private constant PROOF2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    uint256 private constant AMOUNT = 25 * 1e18;
    bytes32[] private PROOFS = [PROOF1, PROOF2];
    address user;
    uint256 privateKey;
    address gasPayer;

    function setUp() public {
        if (!isZkSyncChain()) {
            //chain verification
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new BagelToken();
            airdrop = new MerkleAirdrop(ROOT, token);
            token.mint(token.owner(), AMOUNT);
            token.transfer(address(airdrop), AMOUNT);
        }
        (user, privateKey) = makeAddrAndKey("user");
        (gasPayer,) = makeAddrAndKey("gasPayer");
    }

    function testUserCanClaim() public {
        
        uint256 balance = token.balanceOf(user);
        assert(balance == 0);

        bytes32 digest = airdrop.getMessageHash(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        
        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT, PROOFS, v, r, s);
        assert(token.balanceOf(user) == AMOUNT);
    }
}
