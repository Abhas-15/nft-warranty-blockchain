// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract FlipkartInvoice is ERC1155, KeeperCompatibleInterface {
    uint256 head;
    uint256 tail;
    struct ProductInfo {
        string ID;
        uint256 product_id;
        uint256 next_index;
        uint256 time_of_purchase;
        uint256 warranty_period;
        address product_owner;
    }
    mapping (uint256 => ProductInfo) products; 

    constructor() ERC1155("") {
        head = 0;
        tail = 0;
    }

    function mintProductNFT(address user_account, uint256 purchased_product_id, uint256 product_warranty_period, string memory transactionID) external {
        _mint(user_account, purchased_product_id, 1, "");
        ProductInfo memory new_product_info = ProductInfo({
            ID: transactionID, 
            product_id: purchased_product_id,
            next_index: tail + 1,
            time_of_purchase: block.timestamp,
            warranty_period: product_warranty_period,
            product_owner: user_account
        });
        products[tail] = new_product_info;
        tail++;
    }

    function decayProductNFT(address user_account, uint256 purchased_product_id) internal {
        _burn(user_account, purchased_product_id, 1);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        ProductInfo memory current_product = products[head];

        if(block.timestamp > current_product.time_of_purchase + current_product.warranty_period) {
            upkeepNeeded = true;
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        ProductInfo memory current_product = products[head];

        if(block.timestamp > current_product.time_of_purchase + current_product.warranty_period) {
            decayProductNFT(current_product.product_owner, current_product.product_id);
            uint256 temp = current_product.next_index;
            delete products[head];
            head = temp;
        }
    }
}