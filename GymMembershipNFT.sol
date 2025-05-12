// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GymMembershipNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    address public minter;
    mapping(address => uint256) public ownerToToken;
    // string private constant DEFAULT_URI = "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-blooms.json";

    constructor(
        address initialOwner
    ) ERC721("Gym Membership NFT", "GYM-NFT") Ownable(initialOwner) {}

    /// @notice Setea el contrato autorizado para mintear (GymControl)
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    // Maintain original function for flexibility
    function safeMint(address to, string memory uri) public returns (uint256) {
        require(
            msg.sender == owner() || msg.sender == minter,
            "Not authorized to mint"
        );

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        ownerToToken[to] = tokenId;

        return tokenId;
    }

    function getTokenIdByOwner(address user) public view returns (uint256) {
        return ownerToToken[user];
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
