// SPDX-License-Identifier: CC0-1.0

// TODO -- change Force back to false in transfer for integration testing

pragma solidity ^0.8.0;

import "../node_modules/hardhat/console.sol";

import {ILSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";

import {LSP8MarketplaceOffer} from "./LSP8MarketplaceOffer.sol";
import {LSP8MarketplacePrice} from "./LSP8MarketplacePrice.sol";
import {LSP8MarketplaceTrade} from "./LSP8MarketplaceTrade.sol";
import {LSP8MarketplaceEscrow} from "./LSP8MarketplaceEscrow.sol";

/**
 * @title LSP8Marketplace contract
 * @author Afteni Daniel (aka B00ste)
 *
 * @notice For reference I will assume LSP8 is the same as NFT.
 * @notice ***Forked and amended to support escrow while IRL products are in delivery
 */

contract LSP8Marketplace is
    LSP8MarketplaceOffer,
    LSP8MarketplacePrice,
    LSP8MarketplaceTrade,
    LSP8MarketplaceEscrow
{
    // -------ADMIN FUNCTIONALITY + TREASURY
    address owner;
    address private TREASURY;

    function setTreasury(address _treasury) public {
        require(msg.sender == owner, "Unauthorised.");
        TREASURY = _treasury;
    }

    // maybe best to have owner == treasury multisig, as owner can change treasury
    constructor() {
        owner = msg.sender;
        TREASURY = msg.sender; //<< ?? see comment above
    }

    // --- User Functionality.

    /**
     * Put an NFT on sale.
     * Allowed token standards: LSP8 (refference: "https://github.com/lukso-network/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset")
     *
     * @param LSP8Address Address of the LSP8 token contract.
     * @param tokenId Token id of the `LSP8Address` NFT that will be put on sale.
     * @param LYXAmount Buyout amount of LYX coins.
     *
     * @notice For information about `ownsLSP8` and `LSP8NotOnSale` modifiers and about `_addLSP8Sale` function check the LSP8MarketplaceSale smart contract.
     * For information about `_addLYXPrice` and `_addLSP7Prices` functions check the LSP8MArketplacePrice smart contract.
     */
    function putLSP8OnSale(
        address LSP8Address,
        bytes32 tokenId,
        uint256 LYXAmount,
        bool[3] memory allowedOffers
    )
        external
        ownsLSP8(LSP8Address, tokenId)
        LSP8NotOnSale(LSP8Address, tokenId)
    {
        _addLSP8Sale(LSP8Address, tokenId, allowedOffers);
        _addLYXPrice(LSP8Address, tokenId, LYXAmount);
    }

    /**
     * Remove LSP8 sale. Also removes all the prices attached to the LSP8.
     * Allowed token standards: LSP8 (refference: "https://github.com/lukso-network/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset")
     *
     * @param LSP8Address Address of the LSP8 token contract.
     * @param tokenId Token id of the `LSP8Address` NFT that is on sale.
     *
     * @notice For information about `ownsLSP8` and `LSP8OnSale` modifiers and about `_removeLSP8Sale` check the LSP8MarketplaceSale smart contract.
     * For information about `_removeLSP8Prices` check the LSP8MArketplacePrice smart contract.
     * For information about `_removeLSP8Offers` check the LSP8MArketplaceOffers smart contract.
     */
    function removeLSP8FromSale(
        address LSP8Address,
        bytes32 tokenId
    ) external ownsLSP8(LSP8Address, tokenId) LSP8OnSale(LSP8Address, tokenId) {
        _removeOffers(LSP8Address, tokenId);
        _removeLSP8Prices(LSP8Address, tokenId);
        _removeLSP8Sale(LSP8Address, tokenId);
    }

    /**
     * Change LYX price for a specific LSP8.
     *
     * @param LSP8Address Address of the LSP8 token contract.
     * @param tokenId Token id of the `LSP8Address` NFT that is on sale.
     * @param LYXAmount buyout amount for the NFT on sale.
     *
     * @notice For information about `ownsLSP8` and `LSP8OnSale` modifiers check the LSP8MarketplaceSale smart contract.
     * For information about `_removeLYXPrice` and `_addLYXPrice` functions check the LSP8MarketplacePrice smart contract.
     */
    function changeLYXPrice(
        address LSP8Address,
        bytes32 tokenId,
        uint256 LYXAmount
    ) external ownsLSP8(LSP8Address, tokenId) LSP8OnSale(LSP8Address, tokenId) {
        _removeLYXPrice(LSP8Address, tokenId);
        _addLYXPrice(LSP8Address, tokenId, LYXAmount);
    }

    //

    /**
     * Buy LSP8 with LYX.
     *
     * @param LSP8Address Address of the LSP8 token contract.
     * @param tokenId Token id of the `LSP8Address` NFT that is on sale.
     *
     * @notice For information about `LSP8OnSale` modifier and `_removeLSP8Sale` method
     * check the LSP8MarketplaceSale smart contract.
     * For information about `sendEnoughLYX` modifier and `_removeLSP8Prices`, `_returnLYXPrice` methods
     * check the LSP8MarketplacePrice smart contract.
     * For information about `_removeLSP8Offers` method check the LSP8MarketplaceOffer smart contract.
     * For information about `_transferLSP8` method check the LSP8MarketplaceTrade smart contract.
     */
    function buyLSP8WithLYX(
        address LSP8Address,
        bytes32 tokenId
    )
        external
        payable
        sendEnoughLYX(LSP8Address, tokenId)
        LSP8OnSale(LSP8Address, tokenId)
    {
        address LSP8Owner = (
            ILSP8IdentifiableDigitalAsset(LSP8Address).tokenOwnerOf(tokenId)
        );
        uint256 amount = _returnLYXPrice(LSP8Address, tokenId);

        _removeOffers(LSP8Address, tokenId);
        _removeLSP8Prices(LSP8Address, tokenId);
        _removeLSP8Sale(LSP8Address, tokenId);

        // set up escrow
        _newEscrowItem(LSP8Address, tokenId, LSP8Owner, msg.sender, amount);

        // send LSP8 to marketplace
        _transferLSP8(
            LSP8Address,
            LSP8Owner,
            payable(address(this)),
            tokenId,
            true,
            1
        ); // <<< TODO: force should be false outside of hardhat

        // send LSP8 value in LYX to marketplace
        payable(address(this)).transfer(msg.value);
    }

    /**
     * Buyer confirms receipt of IRL item and releases digital assets.
     * Sends LSP8 to buyer and LYX to seller, including sending
     * 10% of sale value to the original minter.
     *
     * @param escId unique escrow ID for the sale.
     *
     * @notice For information about `itemExists` modifier and about `_getEscrowItem` and `_closeItemRemoveBalance` functions check the LSP8MarketplaceEscrow smart contract.
     */
    function confirmReceipt(uint256 escId) public itemExists(escId) {
        EscrowItem memory item = _getEscrowItem(escId);

        require(msg.sender == item.buyer, "You are not buyer of this item.");
        require(item.balance > 0, "Assets have already been claimed.");

        //transfer LSP8
        _transferLSP8(
            item.LSP8Collection,
            address(this),
            item.buyer,
            item.tokenId,
            true,
            1
        ); // <<TODO: force=false outside of hardhat

        //transfer LYX
        uint256 sellerLYX = ((item.balance) * 90) / 100;
        uint256 royaltyLYX = ((item.balance) * 10) / 100;
        payable(item.seller).transfer(sellerLYX);
        payable(item.OGminter).transfer(royaltyLYX);

        //emit Events
        emit Transfer("LSP8 sent to new owner.", address(this), 1, "");
        emit Transfer("LYX sent to seller.", address(this), sellerLYX, "");
        emit Transfer("Royalty sent to minter.", address(this), royaltyLYX, "");

        //close EscrowItem
        escrowBalance -= item.balance;
        totalConfirmed++;
        _closeItemRemoveBalance(escId);
    }

    /**
     * Seller withdraws sale and releases digital assets.
     * Returns LSP8 to seller and LYX to buyer.
     *
     * @param escId unique escrow ID for the sale.
     *
     * @notice For information about `itemExists` modifier and about `_getEscrowItem` and `_closeItemRemoveBalance` functions check the LSP8MarketplaceEscrow smart contract.
     */
    function reportWithdraw(uint256 escId) public itemExists(escId) {
        EscrowItem memory item = _getEscrowItem(escId);

        require(msg.sender == item.seller, "You are not seller of this item.");
        require(item.balance > 0, "Assets have already been claimed.");

        //return LSP8
        _transferLSP8(
            item.LSP8Collection,
            address(this),
            item.seller,
            item.tokenId,
            true,
            1
        ); // <<TODO: force=false outside of hardhat

        //return LYX
        payable(item.buyer).transfer(item.balance);

        //emit Events
        emit Transfer("LSP8 returned seller.", address(this), 1, "");
        emit Transfer("LYX returned to buyer", address(this), item.balance, "");

        //close EscrowItem
        escrowBalance -= item.balance;
        totalConfirmed++;
        _closeItemRemoveBalance(escId);
    }

    /**
     * Buyer reports an issue which cannot be resolved with the seller.
     * Digital assets are withheld and sent to the Treasury address.
     *
     * @param escId unique escrow ID for the sale.
     *
     * @notice For information about `itemExists` modifier and about `_getEscrowItem` and `_closeItemRemoveBalance` functions check the LSP8MarketplaceEscrow smart contract.
     */
    function reportDispute(uint256 escId) public itemExists(escId) {
        EscrowItem memory item = _getEscrowItem(escId);

        require(msg.sender == item.buyer, "You are not buyer of this item.");
        require(item.balance > 0, "Assets have already been claimed.");

        //withhold LSP8
        _transferLSP8(
            item.LSP8Collection,
            address(this),
            TREASURY,
            item.tokenId,
            true,
            1
        ); // <<TODO: force=false outside of hardhat

        //withhold LYX
        payable(TREASURY).transfer(item.balance);

        //emit Events
        emit Transfer("LSP8 sent to Treasury.", address(this), 1, "");
        emit Transfer("LYX sent to Treasury", address(this), item.balance, "");

        //close EscrowItem
        escrowBalance -= item.balance;
        totalDisputed++;
        _closeItemRemoveBalance(escId);
    }
}
