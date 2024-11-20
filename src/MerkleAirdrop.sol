// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");
    bytes private constant SIGNATURE = hex"612905cf76a56eb88718b51a462a6c6e910d3be43523998814b859aca7e2975616b7834dbe9748c45222a8c50836d0cf609816c30f7979e40a57b6638d9dc9911b";

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_token;
    mapping(address => bool) private s_alreadyClaimed;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    event Claim(address, uint256);

    constructor(bytes32 merkleroot, IERC20 token) EIP712("MerkleAirdop", "1") {
        i_merkleRoot = merkleroot;
        i_token = token;
    }
    // merkeleProof is an array containing sibling hashes on the branch from the leaf to the root of the tree. Each
    // pair of leaves and each pair of pre-images are assumed to be sorted.

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_alreadyClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        //check signature
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_alreadyClaimed[account] = true;
        emit Claim(account, amount);
        i_token.safeTransfer(account, amount);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function _isValidSignature(address signer, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return (actualSigner == signer);
    }
}
