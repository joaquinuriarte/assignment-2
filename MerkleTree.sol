//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        uint256[2] memory messenger;
        for (uint256 i = 0; i < 14; i++) {
            hashes.push(0);
        }
        for (uint256 i = 8; i > 0; i--) {
            if (index < 8) {
                hashes[index] = 0;
                hashes[index+1] = 0;
            }
            if (index == 12) {
                messenger[0] = hashes[index];
                messenger[1] = hashes[index+1];
                root = PoseidonT3.poseidon(messenger);
                index = 0;
                break;
            }
            messenger[0] = hashes[index];
            messenger[1] = hashes[index+1];
            hashes[index + i] = PoseidonT3.poseidon(messenger);
            index = index + 2;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require (index < 8);
        uint256[2] memory messenger; 
        hashes[index] = hashedLeaf;
        uint256 indexHolder = index;
        for (uint256 i = 8; i > 0; i--) {
            if (index == 12 || index == 13) {
                if (index % 2 == 0) {
                    messenger[0] = hashes[index];
                    messenger[1] = hashes[index+1];
                    break;
                } else {
                    messenger[0] = hashes[index-1];
                    messenger[1] = hashes[index];
                    break;
                }
            } else if (index % 2 == 0) {
                messenger[0] = hashes[index];
                messenger[1] = hashes[index+1];
                hashes[(index/2)+8] = PoseidonT3.poseidon(messenger);
            } else {
                messenger[0] = hashes[index-1];
                messenger[1] = hashes[index];
                hashes[(index/2)+8] = PoseidonT3.poseidon(messenger);
            }
            index = (index/2)+8;
        }
        index = indexHolder + 1;
        root = PoseidonT3.poseidon(messenger);
        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return verifyProof(a, b, c, input) && root == input[0];
    }
}
