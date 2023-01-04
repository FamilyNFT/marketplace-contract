// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";

contract FamilyNft is LSP8IdentifiableDigitalAsset {
    uint256 count;
    mapping(bytes32 => string) metadataUri;
    mapping(bytes32 => address) private minter;

    constructor()
        LSP8IdentifiableDigitalAsset("FAMILYNFT", "FNFT", msg.sender)
    {}

    function mint(address to, string memory data) public {
        bytes32 Count = bytes32(count);
        metadataUri[Count] = data;
        bytes memory metadata = bytes(data);
        _mint(to, Count, true, metadata);
        count += 1;
    }

    function getMetadata(bytes32 tokenId) public view returns (string memory) {
        return metadataUri[tokenId];
    }

    function getMinter(bytes32 tokenId) public view returns (address) {
        require(_exists(tokenId) == true);
        return minter[tokenId];
    }
}
