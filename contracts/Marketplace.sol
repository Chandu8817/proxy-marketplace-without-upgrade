// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
contract MarketPlace is ERC721URIStorageUpgradeable {
    uint256 tokenCouter;

    mapping(uint256 => bool)  public ListNftOnRent;

    mapping(uint256 => uint256) public nftRentDuration;
    mapping(uint256 => address) public NftRentBy;

    

    function initialize() public initializer {
        __ERC721_init("ABC NFTs", "ABC");
    }

    // tokenURI is a url which we get when we store data on ipfs via meta data  ie; name,timeduration and uploaded image url
    function mint(string memory _tokenURI) public {
        tokenCouter += 1;
        uint256 _tokenId = tokenCouter;
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function RentNFT(uint256 _tokenId) public payable {
        uint256 rentPrice =10000 wei;
        uint256  rentDuration = 30 days;
        require(
            msg.value >= rentPrice,
            "amount must be greater or equal to msg.value"
        );
        address _owner = ownerOf(_tokenId);
        (bool sent, bytes memory data) = payable(_owner).call{
            value: msg.value
        }("");
        require(sent, "Failed to send Ether"); 
        require(ListNftOnRent[_tokenId], "NFT not available for rent");
        require(
            nftRentDuration[_tokenId] < block.timestamp,
            "NFT already on rent"
        );
        uint256 time =block.timestamp ;
        nftRentDuration[_tokenId] = (time+rentDuration);
        NftRentBy[_tokenId] = msg.sender;
    }

    function getRentNFT(uint256 _tokenId, address _buyer)
        public
        view
        returns (address, bool)
    {
        address _owner = ownerOf(_tokenId);
        require(NftRentBy[_tokenId] == _buyer, "NFT not rent by this user");
        if (block.timestamp< nftRentDuration[_tokenId] ) {
            return (_owner, true);
        } else {
            return (_owner, false);
        }
    }

    function ListNFTForRent(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "User is not owner of NFT");
         require(
            nftRentDuration[_tokenId] < block.timestamp,
            "NFT already on rent"
        );

        ListNftOnRent[_tokenId] = true;
    }

    function UnListNFTFromRent(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "User is not owner of NFT");
        require(
            nftRentDuration[_tokenId] < block.timestamp,
            "NFT already on rent"
        );

        ListNftOnRent[_tokenId] = false;
    }

    receive() external payable  {}

    

}
