// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";

contract familynft is LSP8IdentifiableDigitalAsset {

    mapping(bytes32 => address) private minter;

    mapping(bytes32 => string) metadataUri;

    constructor() LSP8IdentifiableDigitalAsset("FAMILYNFT", "FNFT", msg.sender) {}

    function getMetadata(bytes32 tokenId) public view returns (string memory) {
        return metadataUri[tokenId];
    }

    function mint(address _minter, address to, string memory data) public {
        bytes32 supply = bytes32(totalSupply() + 1);
        metadataUri[supply] = data;
        minter[supply] = _minter;
        bytes memory metadata = bytes(data);
        _mint(to, supply, true, metadata);
    }

    function getMinter(bytes32 tokenId) public view returns (address) {
        require(_exists(tokenId) == true);
        return minter[tokenId];
    }
}
