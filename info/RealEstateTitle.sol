// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateTitle is ERC721Enumerable, Ownable {

    // Custom struct to hold property details
    struct Property {
        string addressDetails;
        uint256 squareFeet;
        uint256 appraisalValue;  // In wei for simplicity
        string otherDetails;  // Can be used to store other details or a link to off-chain data
    }

    // Mapping from token ID to Property details
    mapping (uint256 => Property) private _propertyDetails;

    constructor() ERC721("RealEstateTitle", "RETT") {}

    // Create a new property NFT
    function mintProperty(
        address to,
        string memory addressDetails,
        uint256 squareFeet,
        uint256 appraisalValue,
        string memory otherDetails
    ) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);

        // Store the property details
        _propertyDetails[newTokenId] = Property({
            addressDetails: addressDetails,
            squareFeet: squareFeet,
            appraisalValue: appraisalValue,
            otherDetails: otherDetails
        });

        return newTokenId;
    }

    // Retrieve property details by token ID
    function getPropertyDetails(uint256 tokenId) external view returns (Property memory) {
        return _propertyDetails[tokenId];
    }

    // Update property details (only by owner)
    function updatePropertyDetails(
        uint256 tokenId,
        string memory addressDetails,
        uint256 squareFeet,
        uint256 appraisalValue,
        string memory otherDetails
    ) external onlyOwner {
        _propertyDetails[tokenId] = Property({
            addressDetails: addressDetails,
            squareFeet: squareFeet,
            appraisalValue: appraisalValue,
            otherDetails: otherDetails
        });
    }
}
