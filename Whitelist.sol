//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/sueun-dev/staking_contract/blob/main/ERC20_Staking.sol";

contract Whitelist is Ownable{
    struct Node {
    bytes32 left;
    bytes32 right;
    }

    mapping(bytes32 => Node) public tree;
    bytes32[] public leaves;

    function addToWhitelist(address[] memory addrArray) public onlyOwner {
        for (uint i = 0; i < addrArray.length; i++) {
            bytes32 leaf = keccak256(abi.encodePacked(addrArray[i]));
            leaves.push(leaf);
        }
        buildTree();
    }

    function removeFromWhitelist(address[] memory addrArray) public onlyOwner {
        for (uint i = 0; i < addrArray.length; i++) {
            bytes32 leaf = keccak256(abi.encodePacked(addrArray[i]));
            for (uint j = 0; j < leaves.length; j++) {
                if (leaves[j] == leaf) {
                    delete leaves[j];
                }
            }
        }
        buildTree();
    }

    function buildTree() public onlyOwner {
        uint leafCount = leaves.length;
        for (uint i = 0; i < leafCount; i += 2) {
            bytes32 left = leaves[i];
            bytes32 right = leaves[i + 1];
            bytes32 node = keccak256(abi.encodePacked(left, right));
            tree[node] = Node(left, right);
        }
    }

    /*
    예시)
    isWhitelisted 함수에서는 주어진 주소를 keccak256 해시 함수를 사용하여 bytes32 타입으로 변환한 후, 
        해당 값이 tree 맵핑에 있는지 없는지를 확인하여 존재하면 true를, 아니면 false를 반환합니다.

    이 코드에서는 isWhitelisted 함수를 호출할 때 "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db" 주소를 입력으로 넣었지만, 
        ddToWhitelist 함수에서는 ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", 
        "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"] 이렇게 두 개의 주소를 추가하여 화이트리스트에 추가하고 있습니다. 
        그리고 buildTree 함수는 leaves 배열에 있는 주소들을 이용하여 Merkle Tree를 구성합니다.

    따라서 "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db" 주소는 화이트리스트에 추가되어 있지만, 
    isWhitelisted 함수에서는 이 주소가 Merkle Tree에서의 위치를 찾을 수 없기 때문에 false를 반환하게 됩니다.

    */

    function isWhitelisted(address addr) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        bytes32 node = leaf;
        while (tree[node].left != bytes32(0) && tree[node].right != bytes32(0)) {
            if (leaf == tree[node].left) {
                node = keccak256(abi.encodePacked(tree[node].left, tree[node].right));
            } else {
                node = keccak256(abi.encodePacked(tree[node].right, tree[node].left));
            }
        }
        return node == leaves[0];
    }

    function isAddressInWhitelist(address addr) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        for(uint i = 0; i < leaves.length; i++){
            if(leaves[i] == leaf){
                return true;
            }
        }
        return false;
    }

}
