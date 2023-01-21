// escrow.sol
// SPDX-License-Identifier: MIT

import "../node_modules/hardhat/console.sol";

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import {LSP8MarketplaceTrade} from "./LSP8MarketplaceTrade.sol";
import {IFamilyNft} from "./FamilyNft.sol";

/**
 * @title LSP8MarketplaceEscrow contract
 * @author Sexton Jim
 *
 * @notice For reference I will assume LSP8 is the same as NFT.
 * @notice ***Additional contract support escrow while IRL products are in delivery
 */

pragma solidity ^0.8.0;

contract LSP8MarketplaceEscrow {
    uint256 public escrowBalance;
    uint256 public totalItems = 0;
    uint256 public totalConfirmed = 0;
    uint256 public totalDisputed = 0;

    mapping(uint256 => EscrowItem) private items; // mapping(uint256 => items) items;
    mapping(address => EscrowItem[]) private itemsOf;
    mapping(uint256 => address) public ownerOf;
    mapping(address => mapping(bytes32 => uint256)) public escrowIdOfToken;

    // ----TESTING FUNCTIONS
    function _getEscrowItem(
        uint256 escId
    ) internal view returns (EscrowItem memory) {
        return items[escId];
    }

    function _closeItemRemoveBalance(uint256 escId) internal {
        items[escId].escrowStatus = status.CLOSED;
        items[escId].balance = 0;
    }

    function getItemIdOfToken(
        address LSP8,
        bytes32 tokenId
    ) public view returns (uint256) {
        return escrowIdOfToken[LSP8][tokenId];
    }

    function getBalance() public view returns (uint256) {
        return escrowBalance;
    }

    function getTotalItems() public view returns (uint256) {
        return totalItems;
    }

    function getBuyerSeller(
        uint256 escId
    ) public view returns (address[2] memory) {
        return [items[escId].buyer, items[escId].seller];
    }

    function getEscrowStatus(
        uint256 escId
    ) public view exists(escId) returns (status) {
        // ) internal view exists(escId) returns (status) {
        return items[escId].escrowStatus;
    }

    function _setUserStatus(
        uint256 escId,
        status newStatus
    ) internal exists(escId) {
        if (msg.sender == items[escId].buyer) {
            items[escId].buyerStatus = newStatus;
        } else if (msg.sender == items[escId].seller) {
            items[escId].sellerStatus = newStatus;
        }
    }

    function _setEscrowStatus(
        uint256 escId,
        status newStatus
    ) internal exists(escId) {
        items[escId].escrowStatus = newStatus;
    }

    struct EscrowItem {
        address LSP8Collection;
        bytes32 tokenId;
        address seller;
        address buyer;
        uint256 balance;
        address OGminter;
        uint256 timestamp;
        status escrowStatus;
        status buyerStatus;
        status sellerStatus; //  what's the point in this? Surely only buy-side matters?
        uint256 escrowId; // is this required, or is it given in mapping?
    }

    enum status {
        OPEN, // 0, trade is ongoing
        SUCCESS, // 1, trade can be collected
        WITHDRAWN, // 2, trade has been withdrawn
        DISPUTED, // 3, trade is in dispute - set period before assets are withheld
        CLOSED // 4, trade has been closed
    }

    fallback() external payable {
        // emit Transfer("fallback", msg.sender, msg.value, msg.data); << add back in once data confirmed
    }

    receive() external payable {
        // emit Transfer("receive", msg.sender, msg.value, bytes("")); << add back in once data confirmed
    }

    event Transfer(string func, address sender, uint256 value, bytes data); // what data?
    event Action(string func, address sender, bytes data); // what data?

    modifier exists(uint256 escId) {
        require(items[escId].timestamp != 0, "Escrow item does not exist.");
        _;
    }
    modifier itemIsOpen(uint256 escId) {
        require(
            items[escId].escrowStatus != status.CLOSED,
            "Escrow item has been closed."
        );
        _;
    }
    modifier isbuyerOrSeller(uint256 escId) {
        require(
            msg.sender == items[escId].buyer ||
                msg.sender == items[escId].seller,
            "You are not buyer or seller of this item."
        );
        _;
    }

    /**
     * Called by marketplace when buyer commits to make payment.
     * Locks LSP8 LYX in escrow until exchange is complete.
     *
     * @param LSP8Address Address of the LSP8 to be transfered.
     * @param tokenId Token escrowId of the LSP8 to be transferred.
     * @param seller Address of the LSP8 sender (aka from).
     * @param buyer Address of the LSP8 receiver (aka to).
     * @param amount Sale price of asset.
     *
     * @return address returns address(this) to receive escrowed LSP8 asset
     *
     * @notice this method can only be called once Buyer commits LYX payment
     */
    function _newEscrowItem(
        address LSP8Address,
        bytes32 tokenId,
        address seller,
        address buyer,
        uint256 amount
    ) internal returns (uint256) {
        uint256 itemId = totalItems++;

        EscrowItem storage item = items[itemId];

        item.LSP8Collection = LSP8Address;
        item.tokenId = tokenId;
        item.seller = seller;
        item.buyer = buyer;
        item.balance = amount;
        item.OGminter = IFamilyNft(LSP8Address).getMinter(tokenId);
        item.timestamp = block.timestamp;
        item.escrowStatus = status.OPEN; // overall esc status
        item.buyerStatus;
        item.sellerStatus;
        item.escrowId = itemId;

        escrowBalance += msg.value;
        emit Action("ESCROW ITEM CREATED", buyer, ""); // what data?
        return item.escrowId;
    }
}
