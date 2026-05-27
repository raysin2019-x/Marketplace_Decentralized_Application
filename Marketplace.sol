// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Marketplace
 * @notice A simple decentralized marketplace where users can list, buy, and cancel items.
 */

contract Marketplace {

    // ─── State ───────────────────────────────────────────────────────────────

    uint256 private listingCount;

    enum Status { Listed, Sold, Cancelled }

    struct Listing {
        uint256 id;
        address payable seller;
        string  name;
        uint256 price;   // in wei
        Status  status;
    }

    mapping(uint256 => Listing) private listings;

    // ─── Events ───────────────────────────────────────────────────────────────

    event ItemListed(
        uint256 indexed id,
        address indexed seller,
        string  name,
        uint256 price
    );

    event ItemSold(
        uint256 indexed id,
        address indexed buyer,
        uint256 price
    );

    event ItemCancelled(
        uint256 indexed id,
        address indexed seller
    );

    // ─── Write Functions ──────────────────────────────────────────────────────

    /**
     * @notice List a new item for sale.
     * @param _name  Human-readable name of the item.
     * @param _price Sale price in wei (must be > 0).
     */
    function listItem(string calldata _name, uint256 _price) external {
        require(_price > 0, "Marketplace: price must be greater than zero");
        require(bytes(_name).length > 0, "Marketplace: name cannot be empty");

        listingCount++;
        listings[listingCount] = Listing({
            id:     listingCount,
            seller: payable(msg.sender),
            name:   _name,
            price:  _price,
            status: Status.Listed
        });

        emit ItemListed(listingCount, msg.sender, _name, _price);
    }

    /**
     * @notice Purchase an active listing by sending the exact price in ETH.
     * @param _id  The listing ID to purchase.
     */
    function buyItem(uint256 _id) external payable {
        Listing storage item = listings[_id];

        require(item.status == Status.Listed,  "Marketplace: item is not available");
        require(msg.sender != item.seller,     "Marketplace: seller cannot buy own item");
        require(msg.value == item.price,       "Marketplace: incorrect ETH amount sent");

        item.status = Status.Sold;

        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Marketplace: ETH transfer to seller failed");

        emit ItemSold(_id, msg.sender, item.price);
    }

    /**
     * @notice Cancel your own active item.
     * @param _id  The listing ID to cancel.
     */
    function cancelItem(uint256 _id) external {
        Listing storage item = listings[_id];

        require(item.status == Status.Listed, "Marketplace: item is not available");
        require(msg.sender == item.seller,    "Marketplace: only seller can cancel");

        item.status = Status.Cancelled;

        emit ItemCancelled(_id, msg.sender);
    }

    // ─── Result Struct (for read functions) ──────────────────────────────────

    struct ListingView {
        uint256 id;
        string  name;
        uint256 price;
        Status  status;
    }

    // ─── Read Functions ───────────────────────────────────────────────────────

    /**
     * @notice Return full details of all active (listed) items.
     */
    function ActiveListings() external view returns (ListingView[] memory) {
        uint256 count;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].status == Status.Listed) count++;
        }

        ListingView[] memory result = new ListingView[](count);
        uint256 idx;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].status == Status.Listed) {
                result[idx] = ListingView({
                    id:     listings[i].id,
                    name:   listings[i].name,
                    price:  listings[i].price,
                    status: listings[i].status
                });
                idx++;
            }
        }
        return result;
    }

    /**
     * @notice Return full details of all sold items.
     */
    function SoldListings() external view returns (ListingView[] memory) {
        uint256 count;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].status == Status.Sold) count++;
        }

        ListingView[] memory result = new ListingView[](count);
        uint256 idx;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].status == Status.Sold) {
                result[idx] = ListingView({
                    id:     listings[i].id,
                    name:   listings[i].name,
                    price:  listings[i].price,
                    status: listings[i].status
                });
                idx++;
            }
        }
        return result;
    }

    /**
     * @notice Return full details of all cancelled items.
     */
    function CancelledListings() external view returns (ListingView[] memory) {
        uint256 count;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].status == Status.Cancelled) count++;
        }

        ListingView[] memory result = new ListingView[](count);
        uint256 idx;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].status == Status.Cancelled) {
                result[idx] = ListingView({
                    id:     listings[i].id,
                    name:   listings[i].name,
                    price:  listings[i].price,
                    status: listings[i].status
                });
                idx++;
            }
        }
        return result;
    }
}
