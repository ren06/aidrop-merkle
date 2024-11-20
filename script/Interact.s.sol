// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    address private constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant AMOUNT_TO_COLLECT = (25 * 1e18); // 25.000000

    bytes32 private constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof = [PROOF_ONE, PROOF_TWO];
    
    // the signature will change every time you redeploy the airdrop contract!
    // steps to generate the signature
    // acc1 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 | 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    // acc2 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 | 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
    // airdrop contract 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
    /* 1) cast call aidrop_contract selector account_value amount_value
        cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getMessageHash(address,uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 25000000000000000000 --rpc-url http://localhost:8545
        => 0x16fa3780050c2152bc87b83f4358e1067482bfb52c4d3a853f7889692d26a368
        2) cast wallet sign --no-hash message_hash --private-key private_key        
        cast wallet sign --no-hash 0x16fa3780050c2152bc87b83f4358e1067482bfb52c4d3a853f7889692d26a368 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        => 0x612905cf76a56eb88718b51a462a6c6e910d3be43523998814b859aca7e2975616b7834dbe9748c45222a8c50836d0cf609816c30f7979e40a57b6638d9dc9911b

        3)
        forge script script/Interact.s.sol:ClaimAirdrop --rpc-url http://localhost:8545 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --broadcast
    
        BagelToken 0x5FbDB2315678afecb367f032d93F642f64180aa3
        cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    
        cast --to-dec 0x000000000000000000000000000000000000000000000015af1d78b58c40000
        => 25000000000000000000
    */
    bytes private constant SIGNATURE = hex"612905cf76a56eb88718b51a462a6c6e910d3be43523998814b859aca7e2975616b7834dbe9748c45222a8c50836d0cf609816c30f7979e40a57b6638d9dc9911b";

    error __ClaimAirdropScript__InvalidSignatureLength();

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        console.log("Claiming Airdrop");
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, AMOUNT_TO_COLLECT, proof, v, r, s);
        vm.stopBroadcast();
        console.log("Claimed Airdrop");
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert __ClaimAirdropScript__InvalidSignatureLength();
        }   
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }
}
