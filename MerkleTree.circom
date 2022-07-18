pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    //hash the deepest level and record resulting hashes in holder array
    signal hashHolder[n][2**(n-1)];
    component p[2**(n-1)];
    var compPlace = 0;
    for (var i = 0; i < (2**n); i = i + 2) {
        p[compPlace] = Poseidon(2);
        p[compPlace].inputs[0] <== leaves[i];
        p[compPlace].inputs[1] <== leaves[i+1];
        hashHolder[n-1][compPlace] <== p[compPlace].out;
        compPlace++;
    }
    // repeat above process using holder array
    var depthTrack = n - 1;
    var newDepth = n - 1;
    component pp[(2**newDepth)-1];
    compPlace = 0;
    var hashPlace = 0;
    for (var ii = 0; ii < newDepth; ii++) {
        for (var iii = 0; iii < (2**depthTrack); iii = iii + 2) {
            pp[compPlace] = Poseidon(2);
            pp[compPlace].inputs[0] <== hashHolder[depthTrack][iii];
            pp[compPlace].inputs[1] <== hashHolder[depthTrack][iii+1];
            hashHolder[depthTrack-1][hashPlace] <== pp[compPlace].out;
            compPlace++;
            hashPlace++;
        }
        hashPlace = 0;
        depthTrack--;
    }
    // return the root hash
    root <== hashHolder[0][0];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    signal hash[n+1];
    hash[0] <== leaf;
    component p[2*n];
    component mux[n];
    var doubleTime = 0;
    for (var i = 0; i < n; i++) {
        mux[i] = Mux1();

        p[doubleTime] = Poseidon(2);
        p[doubleTime].inputs[0] <== hash[i];
        p[doubleTime].inputs[1] <== path_elements[i];
        mux[i].c[0] <== p[doubleTime].out;
        
        p[doubleTime+1] = Poseidon(2);
        p[doubleTime+1].inputs[0] <== path_elements[i];
        p[doubleTime+1].inputs[1] <== hash[i];
        mux[i].c[1] <== p[doubleTime+1].out;
        
        mux[i].s <== path_index[i];
        hash[i+1] <== mux[i].out;
        doubleTime = doubleTime + 2;
    }
    root <== hash[n];
}