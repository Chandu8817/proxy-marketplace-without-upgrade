// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ProxyContract is Proxy, ERC1967Upgrade {
    struct Buyer {
        address offerBy;
        uint256 amount;
        uint256 time;
        bool accepted;
    }
    mapping(uint256 => mapping(address => Buyer)) Offer;

    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address impl)
    {
        return ERC1967Upgrade._getImplementation();
    }

    function MakeAnOffer(
        address _erc721Address,
        uint _tokenId,
        uint256 _amount
    ) public payable {
        IERC721 NFTContract = IERC721(_erc721Address);
        require(
            msg.value >= _amount,
            "amount must be greater or equal to msg.value"
        );
        address nftOwner = NFTContract.ownerOf(_tokenId);
        require(nftOwner != address(0), "Owner of token is not existing");
        Buyer memory _buyer = Buyer(
            msg.sender,
            _amount,
            block.timestamp,
            false
        );
        Offer[_tokenId][_erc721Address] = _buyer;
    }

    function AcceptOffer(address _erc721Address, uint _tokenId) public {
        Buyer memory _buyer = FetchAnOffer(_erc721Address, _tokenId);

        IERC721 NFTContract = IERC721(_erc721Address);
        address nftOwner = NFTContract.ownerOf(_tokenId);
        require(nftOwner == msg.sender, "Token owner is  invalid");
        NFTContract.transferFrom(msg.sender, _buyer.offerBy, _tokenId);
        (bool sent, bytes memory data) = payable(msg.sender).call{
            value: _buyer.amount
        }("");
        require(sent, "Failed to send Ether");
        delete Offer[_tokenId][_erc721Address];
    }

    function FetchAnOffer(address _erc721Address, uint256 _tokenId)
        public
        view
        returns (Buyer memory)
    {
        return Offer[_tokenId][_erc721Address];
    }

    function RejectOffer(address _erc721Address, uint256 _tokenId) public {
        IERC721 NFTContract = IERC721(_erc721Address);
        Buyer memory _buyer = FetchAnOffer(_erc721Address, _tokenId);

        address nftOwner = NFTContract.ownerOf(_tokenId);
        require(nftOwner == msg.sender, "Token owner is  invalid");
        (bool sent, bytes memory data) = payable(_buyer.offerBy).call{
            value: _buyer.amount
        }("");
        require(sent, "Failed to send Ether");

        delete Offer[_tokenId][_erc721Address];
    }

    receive() external payable override {}
}
