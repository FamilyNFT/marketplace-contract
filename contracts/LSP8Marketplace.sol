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
        returns (uint256)
    {
        address LSP8Owner = (
            ILSP8IdentifiableDigitalAsset(LSP8Address).tokenOwnerOf(tokenId)
        );
        uint256 amount = _returnLYXPrice(LSP8Address, tokenId);

        _removeOffers(LSP8Address, tokenId);
        _removeLSP8Prices(LSP8Address, tokenId);
        _removeLSP8Sale(LSP8Address, tokenId);

        // set up escrow
        uint256 escrowId = _newEscrowItem(
            LSP8Address,
            tokenId,
            LSP8Owner,
            msg.sender,
            amount
        );

        // escrow in marketplace contract
        _transferLSP8(
            LSP8Address,
            LSP8Owner,
            payable(address(this)),
            tokenId,
            true,
            1
        ); // <<< TODO: force should be false outside of hardhat

        payable(address(this)).transfer(msg.value);

        // return escrow id to front end
        return escrowId;
    }

    // ------ESCROW FUNCTIONALITY

    // ----if both parties report success, assets can be sent
    function reportDeliverySuccess(
        uint256 escId
    ) public exists(escId) itemIsOpen(escId) isbuyerOrSeller(escId) {
        _reportDeliverySuccess(escId);
    }

    // ----if one party reports disputed, the item is disputed
    // ----if two parties report disputed, a countdown starts to withhold
    function reportDispute(
        uint256 escId
    ) public exists(escId) itemIsOpen(escId) isbuyerOrSeller(escId) {
        _reportDispute(escId);
    }

    // ----if both parties report withdrawn, assets can be returned
    function reportWithdrawn(
        uint256 escId
    ) public exists(escId) itemIsOpen(escId) isbuyerOrSeller(escId) {
        _reportWithdrawn(escId);
    }

    /**
     * Called by buyer or seller once escrow has concluded.
     * Checks escrowStatus and if SUCCESS, transfers LSP8 to buyer and LYX to seller,
     * if WITHDRAWN transfers LSP8 to seller and LYX to buyer. For other escrowStatus
     * the call will revert.
     */
    function transferAssetsLSP8LYX(
        uint256 escId
    ) public payable exists(escId) itemIsOpen(escId) isbuyerOrSeller(escId) {
        EscrowItem memory item = _getEscrowItem(escId);
        require(
            getEscrowStatus(escId) == status.SUCCESS,
            "Both parties must agree on success before transfer."
        );
        if (item.escrowStatus == status.SUCCESS) {
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
            uint256 sellerLYX = ((item.amount) * 90) / 100;
            uint256 royaltyLYX = ((item.amount) * 10) / 100;
            payable(item.buyer).transfer(sellerLYX);
            payable(item.OGminter).transfer(royaltyLYX);

            // update item and Escrow state variables
            _closeItem(escId);
            // escrowBalance -= items[escId].amount;
            escrowBalance -= msg.value;
            totalConfirmed++;

            emit Transfer("LSP8 sent to new owner.", address(this), 1, ""); // Todo: "value"=msg.value?
            emit Transfer("LYX sent to seller.", address(this), sellerLYX, "");
            emit Transfer(
                "Royalty sent to Minter.",
                address(this),
                royaltyLYX,
                ""
            );
        }
    }
}
