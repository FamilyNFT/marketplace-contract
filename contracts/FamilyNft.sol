// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";

// import "../node_modules/hardhat/console.sol";

contract FamilyNft is LSP8IdentifiableDigitalAsset {
    uint256 count;
    mapping(bytes32 => address) private minter;
    mapping(bytes32 => string) metadataUri;

    constructor()
        LSP8IdentifiableDigitalAsset("FAMILYNFT", "FNFT", msg.sender)
    {}

    function mint(address to, string memory data) public onlyOwner {
        bytes32 tokenId = bytes32(count);
        minter[tokenId] = to;
        metadataUri[tokenId] = data;
        bytes memory metadata = bytes(data);
        _mint(to, tokenId, true, metadata);
        count += 1;
    }

    function getMetadata(bytes32 tokenId) public view returns (string memory) {
        require(_exists(tokenId) == true, "TokenId does not exist");
        return metadataUri[tokenId];
    }

    function getMinter(bytes32 tokenId) public view returns (address) {
        require(_exists(tokenId) == true, "TokenId does not exist");
        return minter[tokenId];
    }

    //////// TESTING FUNCTIONS

    // suggest removing 'count' to use inherited 'totalSupply()'
    // suggest removing 'getCount()'. Can use inherited 'totalSupply()'
    function getCount() public view onlyOwner returns (uint256) {
        return count;
    }
}
